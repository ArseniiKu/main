# Отчет по лабораторной работе №7
## Углубленный Kubernetes: ConfigMaps, Secrets, Persistent Volumes, Ingress и Traefik Dashboard

---

## Цель работы
Изучение продвинутых возможностей Kubernetes: управление конфигурацией через ConfigMaps и Secrets, обеспечение персистентности данных с помощью Persistent Volumes, настройка маршрутизации через Ingress (Traefik) и использование Traefik Dashboard.

---

## Архитектура

- **Кластер:** K3s v1.36.5
- **Master:** ubuntuu (10.3.51.1)
- **Workers:** node1 (10.3.51.99), node2 (10.3.51.118)
- **Ingress Controller:** Traefik v2 (встроен в K3s)
- **StorageClass:** local-path

---

## Часть A: ConfigMaps и Secrets

### Что сделано:
1. Создан ConfigMap `nginx-config` с HTML-контентом
2. Создан Secret `db-credentials` с учетными данными БД (base64)
3. Deployment `configured-nginx` использует:
   - Secret → переменные окружения `MY_DB_USER`, `MY_DB_PASS`
   - ConfigMap → файл `/usr/share/nginx/html/index.html`

### Результаты проверки:
```bash
$ kubectl exec $POD -- env | grep MY_DB
MY_DB_USER=admin
MY_DB_PASS=super_secret_password

$ kubectl exec $POD -- cat /usr/share/nginx/html/index.html
<h1>Hello from ConfigMap!</h1>
<p>Environment: Production</p>
Часть B: Persistent Volumes
Что сделано:

    Создан PVC nginx-pvc (100Mi, ReadWriteOnce, local-path)
    Deployment stateful-nginx монтирует PVC в /usr/share/nginx/html
    Проведен тест на выживание: запись данных → удаление пода → проверка нового пода

Результаты теста:
# Запись данных (через sh, т.к. Alpine не имеет bash)
$ kubectl exec $POD -- sh -c 'echo "Persistent Data Test 123" > /usr/share/nginx/html/data.txt'

# Удаление пода
$ kubectl delete pod $POD

# Проверка нового пода
$ kubectl exec $NEW_POD -- cat /usr/share/nginx/html/data.txt
Persistent Data Test 123
Вывод: Данные сохранились после пересоздания пода, что подтверждает работу PVC.
Часть C: Ingress и Traefik
Что сделано:

    Создан Service ingress-nginx-svc (ClusterIP) для приложения из Части A
    Создан Ingress my-ingress с правилом маршрутизации для app.local
    Добавлена запись в /etc/hosts: 10.3.51.1 app.local
    Изменен тип Service Traefik на NodePort (порт 31084)

Результаты проверки:
$ curl http://10.3.51.1:31084 -H "Host: app.local"
<h1>Hello from ConfigMap!</h1>
<p>Environment: Production</p>
Traefik успешно маршрутизирует HTTP-запросы на уровне L7.
Часть D: Traefik Dashboard
Что сделано:

    Создан HelmChartConfig для включения Dashboard
    Traefik перезапущен с флагами --api.dashboard=true и --api.insecure=true
    Dashboard доступен через port-forward на порт 9000 (пробрасывается на 8080 внутри пода)
На скриншоте видно правило маршрутизации для app.local с path /.
```
Ответы на контрольные вопросы
Вопрос 1: Почему значения в Secret хранятся в base64, а не в зашифрованном виде? Как прочитать содержимое Secret одной командой kubectl?
Ответ:
Kubernetes хранит Secrets в base64 по умолчанию, потому что:
`
    Base64 — это кодировка, а не шифрование. Она нужна для безопасной передачи бинарных данных через JSON/YAML (избегает проблем со спецсимволами).
    Историческая причина: Kubernetes спроектирован так, что безопасность должна обеспечиваться на уровне etcd (шифрование at-rest), RBAC (контроль доступа) и network policies. Сам по себе Secret — это просто "пометка" для администратора, что данные конфиденциальны.
    Для реального шифрования в production используют:
        External Secrets Operator (интеграция с AWS Secrets Manager, HashiCorp Vault)
        EncryptionConfiguration для etcd (шифрование на уровне хранилища)
        Sealed Secrets (шифрование Secrets для хранения в Git)

Команда для чтения Secret:
# Декодировать конкретное значение
kubectl get secret db-credentials -o jsonpath='{.data.DB_USER}' | base64 --decode
# Вывод: admin

# Или посмотреть все значения сразу
kubectl get secret db-credentials -o yaml
# Затем декодировать каждое поле вручную
Вопрос 2: Что произойдет, если в Части B поставить replicas: 2 для PVC с режимом ReadWriteOnce?
Ответ:
При replicas: 2 и PVC с accessModes: ReadWriteOnce произойдет следующее:
``
    Первый под успешно запустится и смонтирует PVC.
    Второй под останется в статусе Pending с ошибкой:
   Warning  FailedScheduling  ...  0/3 nodes are available: 
   pod has unbound immediate PersistentVolumeClaims.
При попытке описать под:
   kubectl describe pod <second-pod>
   В событиях будет видно:
   Multi-Attach error for volume "pvc-..." 
   Volume is already exclusively attached to one node and can't be attached to another
Причина: Режим ReadWriteOnce (RWO) означает, что том может быть примонтирован только к одному узлу одновременно. Это ограничение большинства локальных хранилищ (local-path, NFS в режиме RWO).
Решения:
`
    Использовать ReadWriteMany (RWX) — требует NFS или CephFS
    Использовать StatefulSet вместо Deployment (каждый под получает свой PVC)
    Оставить replicas: 1 для stateful-приложений

Вопрос 3: Какую роль играет ingressClassName: traefik? Что было бы, если бы мы его не указали?
Ответ:
Роль ingressClassName:
`
    Указывает Kubernetes, какой Ingress Controller должен обрабатывать этот Ingress-ресурс.
    В кластере может быть несколько Ingress Controllers (Traefik, Nginx Ingress, HAProxy, etc.).
    ingressClassName: traefik говорит: "Используй Traefik для маршрутизации этого Ingress".

Если не указать:
`
    Вариант А: Если в кластере только один Ingress Controller (Traefik), он может быть назначен по умолчанию (если у него есть аннотация ingressclass.kubernetes.io/is-default-class: "true"). В K3s Traefik обычно является default.
    Вариант Б: Если есть несколько контроллеров или нет default — Ingress останется в статусе без адреса, и маршрутизация не заработает.
    Вариант В: В старых версиях Kubernetes использовались аннотации (kubernetes.io/ingress.class: traefik), но сейчас это deprecated.

Рекомендация: Всегда явно указывать ingressClassName для избежания неоднозначности.
Вопрос 4: Скриншот HTTP Routers в Traefik Dashboard
На скриншоте видно правило:


Rule: Host(`app.local`) && PathPrefix(`/`)
Что это означает:

    Host(app.local) — Traefik проверяет HTTP-заголовок Host и сравнивает с app.local. Если запрос пришел на другой домен (например, example.com), правило не сработает.
    PathPrefix(/) — Traefik проверяет URL-путь. PathPrefix("/") означает "любой путь, начинающийся с /" (то есть вообще любой путь).
    && — логическое И: оба условия должны выполняться одновременно.
Дополнительные примеры правил:

    Host(app.local) && PathPrefix(/api) — только пути /api/*
    Host(app.local) || Host(www.app.local) — оба домена
    PathPrefix(/static) && Method(GET) — только GET-запросы на /static/*
Выводы
`
    ConfigMaps и Secrets позволяют отделять конфигурацию от кода приложения (12-Factor App methodology).
    Persistent Volumes обеспечивают сохранность данных при перезапуске подов, что критично для stateful-приложений (БД, файловые хранилища).
    Ingress (Traefik) предоставляет маршрутизацию на уровне L7 (HTTP), позволяя направлять трафик на разные сервисы по домену и пути.
    Traefik Dashboard дает визуальное представление о маршрутизации и помогает в отладке.
    Безопасность: Secrets в Kubernetes по умолчанию не зашифрованы — для production нужна дополнительная защита (etcd encryption, External Secrets Operator).

Кластер готов к развертыванию production-приложений с полным набором функций Kubernetes!
