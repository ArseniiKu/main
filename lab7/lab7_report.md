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
```
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
```
Часть C: Ingress и Traefik
Что сделано:

    Создан Service ingress-nginx-svc (ClusterIP) для приложения из Части A
    Создан Ingress my-ingress с правилом маршрутизации для app.local
    Добавлена запись в /etc/hosts: 10.3.51.1 app.local
    Изменен тип Service Traefik на NodePort (порт 31084)
```
Результаты проверки:
$ curl http://10.3.51.1:31084 -H "Host: app.local"
<h1>Hello from ConfigMap!</h1>
<p>Environment: Production</p>
Traefik успешно маршрутизирует HTTP-запросы на уровне L7.
```
Часть D: Traefik Dashboard
Что сделано:

    Создан HelmChartConfig для включения Dashboard
    Traefik перезапущен с флагами --api.dashboard=true и --api.insecure=true
    Dashboard доступен через port-forward на порт 9000 (пробрасывается на 8080 внутри пода)
На скриншоте видно правило маршрутизации для app.local с path /.
```
Ответы на контрольные вопросы
Вопрос 1. Почему значения Secret хранятся в base64, а не в зашифрованном виде? Как прочитать содержимое Secret одной командой?
Base64 — это кодирование, а не шифрование. Его задача — представить произвольные двоичные данные в виде текста, пригодного для JSON/YAML, чтобы избежать проблем со спецсимволами. Kubernetes изначально исходит из того, что конфиденциальность обеспечивается на других уровнях: шифрованием etcd, RBAC и сетевыми политиками. Сам Secret — скорее маркер для администратора, чем средство защиты.

Для реальной защиты в продакшене применяют:

External Secrets Operator (интеграция с AWS Secrets Manager, HashiCorp Vault);

EncryptionConfiguration для etcd — шифрование на уровне хранилища;

Sealed Secrets — шифрование Secrets для хранения в Git.

Чтение Secret одной командой:

kubectl get secret db-credentials -o jsonpath='{.data.DB_USER}' | base64 --decode
# admin

Либо вывести весь объект (kubectl get secret db-credentials -o yaml) и декодировать нужные поля вручную.

Вопрос 2. Что произойдёт, если в части B указать replicas: 2 для PVC с режимом ReadWriteOnce?
Первый под смонтирует PVC и запустится. Второй останется в Pending: планировщик не сможет разместить его, поскольку том уже подключён к одному узлу. В событиях пода будет Multi-Attach error for volume "pvc-...", а в describe — сообщение о несвязанных немедленных PVC.

Причина в семантике ReadWriteOnce: том может быть подключён только к одному узлу одновременно — это ограничение большинства локальных хранилищ (включая local-path).

Варианты решения:

использовать ReadWriteMany (нужен NFS или CephFS);

перейти на StatefulSet — каждый под получит собственный PVC;

оставить replicas: 1 для stateful-приложений.

Вопрос 3. Какую роль играет ingressClassName: traefik? Что было бы без него?
ingressClassName указывает, какой Ingress-контроллер должен обрабатывать данный Ingress. В кластере может быть несколько контроллеров (Traefik, Nginx Ingress, HAProxy), и это поле снимает неоднозначность: traefik означает «маршрутизируй через Traefik».

Если поле не указать:

Вариант А: при единственном контроллере с аннотацией ingressclass.kubernetes.io/is-default-class: "true" он будет выбран по умолчанию. В K3s Traefik обычно и есть контроллер по умолчанию.

Вариант Б: при нескольких контроллерах без default Ingress останется без адреса, и маршрутизация не заработает.

Вариант В: в старых версиях Kubernetes использовалась аннотация kubernetes.io/ingress.class: traefik, но она устарела.

Рекомендация — указывать ingressClassName явно, чтобы поведение было предсказуемым.

Вопрос 4. Скриншот HTTP-маршрутизаторов в Traefik Dashboard
На скриншоте видно правило: 

Host(app.local) && PathPrefix(/)

Что оно означает:

Host(app.local) — Traefik сравнивает HTTP-заголовок Host с app.local; запросы на другой домен правило не пройдут.

PathPrefix(/) — проверяется URL-путь; / означает «любой путь, начинающийся с /», то есть фактически любой.

&& — логическое И: оба условия должны выполняться одновременно.

Другие примеры правил:

Host(app.local) && PathPrefix(/api) — только пути /api/*;

Host(app.local) || Host(www.app.local) — оба домена;

PathPrefix(/static) && Method(GET) — только GET-запросы на /static/*.

Выводы
ConfigMaps и Secrets позволяют отделить конфигурацию от кода приложения (подход 12-Factor App).

Persistent Volumes обеспечивают сохранность данных при пересоздании подов — это критично для stateful-приложений (БД, файловые хранилища).

Ingress (Traefik) реализует маршрутизацию на уровне L7, направляя трафик на разные сервисы по домену и пути.

Traefik Dashboard даёт наглядное представление о маршрутизации и упрощает отладку.

Секреты в Kubernetes по умолчанию не зашифрованы — для продакшена нужна дополнительная защита (шифрование etcd, External Secrets Operator).

Кластер готов к развёртыванию продакшен-приложений с полным набором возможностей Kubernetes.


