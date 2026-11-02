# Отчет по лабораторной работе №8
## Helm: упаковка приложений и мониторинг в Kubernetes



---

## Цель работы
Создание собственных Helm-чартов, управление жизненным циклом релизов, работа с разными окружениями (dev/prod), развёртывание стека мониторинга (Prometheus + Grafana) и настройка алертинга.

---

## Архитектура

- **Кластер:** K3s v1.36.5
- **Master:** ubuntuu (10.3.51.1)
- **Workers:** node1, node2
- **Helm:** v3.22.1
- **Мониторинг:** Prometheus v2.45.0 + Grafana v10.0.3

---

## Часть A: Helm Fundamentals

### Что сделано:
1. Создан чарт `myapp-chart` с помощью `helm create`
2. Настроен `values.yaml` с параметрами приложения
3. Адаптированы шаблоны Deployment и ConfigMap
4. Установлен релиз `myapp`
5. Проведены операции upgrade и rollback

### Результаты:
```bash
$ helm history myapp
REVISION  UPDATED                   STATUS      CHART           APP VERSION
1         2026-10-30                superseded  myapp-chart-0.1.0  1.16.0
2         2026-10-30                superseded  myapp-chart-0.1.0  1.16.0
3         2026-10-30                superseded  myapp-chart-0.1.0  1.16.0
4         2026-10-30                deployed    myapp-chart-0.1.0  1.16.0
```
Часть B: Окружения и пакетирование
Что сделано:

    Созданы файлы dev-values.yaml и prod-values.yaml
    Установлены два релиза: myapp-dev (1 реплика) и myapp-prod (3 реплики в namespace production)
    Чарт упакован в .tgz архив

Результаты:
$ helm list --all-namespaces
NAME              NAMESPACE    REVISION  STATUS    CHART
myapp-dev         default      1         deployed  myapp-chart-0.1.0
myapp-prod        production   1         deployed  myapp-chart-0.1.0
myapp-from-package default     1         deployed  myapp-chart-1.0.0
Часть C: Чарт мониторинга
Что сделано:

    Создан чарт monitoring-chart с Prometheus и Grafana
    Prometheus настроен на сбор метрик с узлов кластера
    Grafana развёрнута с NodePort 30300

Результаты:
$ kubectl get pods -n monitoring
NAME                          READY   STATUS    RESTARTS   AGE
grafana-xxxxx-xxxxx           1/1     Running   0          5m
prometheus-xxxxx-xxxxx        1/1     Running   0          5m
Часть D: Визуализация и алертинг
Что сделано:

    Подключён Prometheus как Data Source в Grafana (URL: http://prometheus:9090)
    Создан дашборд "K8s Overview" с панелями:
        Target Status (метрика up)
        Pod Restarts (метрика prometheus_tsdb_head_series)

Примечание: Метрика kube_pod_container_status_restarts_total требует kube-state-metrics, который не был установлен из-за ограничений ресурсов. Использована альтернативная метрика Prometheus.


Скриншот дашборда:
<img width="1188" height="662" alt="image" src="https://github.com/user-attachments/assets/032cf688-23cc-42c8-9604-6e4512032117" />

Ответы на контрольные вопросы
Вопрос 1: Helm Rollback — что происходит в кластере?
Ответ:
При выполнении helm rollback myapp 1:

    Helm обращается к истории релизов, которая хранится в Kubernetes Secrets в namespace релиза (по умолчанию default). Каждый релиз сохраняется как Secret с именем sh.helm.release.v1.<release-name>.v<revision>.
    Helm берёт манифесты из указанной ревизии (в данном случае v1) и применяет их к кластеру через Kubernetes API.
    Kubernetes выполняет rolling update — плавно заменяет текущие поды на поды из старой конфигурации.
    Создаётся новая запись в истории — rollback тоже считается ревизией. То есть после rollback myapp 1 появляется ревизия v4, которая идентична v1.

Где хранится история: В объектах Secret в namespace релиза:
kubectl get secrets -l owner=helm,name=myapp
Вопрос 2: Go Templating — {{- toYaml .Values.prometheus.resources | nindent 10 }}
Ответ:
Разберём по частям:

    {{- ... }} — знак минус после {{ означает удаление пробелов и переносов строк перед конструкцией. Это нужно для корректного форматирования YAML.
    toYaml — встроенная функция Helm/Go, которая преобразует объект (map, list) в YAML-строку.
    .Values.prometheus.resources — обращение к значению из values.yaml: limits: {cpu: 200m, memory: 256Mi} и requests: {...}.
    | nindent 10 — pipe-оператор: сначала результат toYaml передаётся в функцию nindent, которая добавляет перенос строки и 10 пробелов отступа перед каждой строкой.

Почему нельзя написать вручную:

    Values могут меняться при установке (--set, -f values.yaml)
    Один шаблон работает для всех окружений (dev/prod)
    DRY-принцип: не дублировать конфигурацию

Пример рендеринга:
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
Вопрос 3: Kubernetes DNS — почему http://prometheus:9090?
Ответ:

    Почему не IP-адрес: Поды в Kubernetes эфемерны — при перезапуске они получают новый IP. Жёстко прописанный IP быстро устареет.
    Как Grafana "узнаёт" где Prometheus: Kubernetes имеет встроенный DNS-сервер (CoreDNS). Когда создаётся Service prometheus, CoreDNS автоматически регистрирует запись prometheus.monitoring.svc.cluster.local (или сокращённо prometheus внутри того же namespace).
    Если под Prometheus пересоздаётся: IP пода меняется, но IP Service остаётся неизменным (ClusterIP). Service работает как стабильный endpoint, который через kube-proxy перенаправляет трафик на актуальные поды. Поэтому Grafana продолжит работать без изменений конфигурации.

Проверка DNS из пода Grafana:
kubectl exec -it <grafana-pod> -n monitoring -- nslookup prometheus
Вопрос 4: Resource Limits — что будет при превышении?
Ответ:
Если под Prometheus попытается потребить 300Mi при лимите 256Mi:

    Ядро Linux активирует OOM Killer (Out Of Memory Killer)
    Контейнер будет завершён с кодом 137 (SIGKILL)
    Статус пода: OOMKilled в поле lastState.terminated.reason
    kubelet перезапустит контейнер (если restartPolicy: Always)

Команды для просмотра событий:
# События пода
kubectl describe pod <prometheus-pod> -n monitoring | grep -A 5 "Events"

# Или конкретно последние события
kubectl get events -n monitoring --field-selector involvedObject.name=<pod-name>

# Проверка лимитов
kubectl get pod <pod-name> -n monitoring -o jsonpath='{.spec.containers[0].resources}'
Почему 256Mi: Prometheus и Grafana — относительно лёгкие приложения. 256Mi достаточно для учебного кластера с небольшим количеством метрик. В production обычно выделяют 1-2 GiB.
Вопрос 5: PromQL — запрос up
Ответ:

    Что возвращает: Метрика up возвращает 1 для каждой цели (target), которая успешно отвечает на scrape-запросы Prometheus, и 0 — для недоступных целей.
    Если возвращает 0: Цель недоступна. Возможные причины:
        Pod упал или перезапускается
        Неправильный адрес в scrape_config
        Сетевые проблемы (NetworkPolicy, firewall)
        Приложение не экспортирует метрики на указанном порту
    Как найти причину:
# 1. Смотрим статус targets в Prometheus UI: Status → Targets
# 2. Проверяем поды
kubectl get pods -n monitoring
# 3. Смотрим события
kubectl describe pod <pod-name> -n monitoring
# 4. Проверяем логи приложения
kubectl logs <pod-name> -n monitoring
# 5. Проверяем Service
kubectl get svc -n monitoring
kubectl describe svc prometheus -n monitoring
Вопрос 6: --set vs -f values.yaml
Ответ:
Характеристика
	
--set key=value
	
-f values.yaml
Синтаксис
	
Флаги в командной строке
	
YAML-файл
Количество параметров
	
1-3 параметра
	
Много параметров
Читаемость
	
Плохо при большом числе
	
Отлично
Версионирование
	
Не сохраняется в Git
	
Сохраняется в Git
Повторяемость
	
Нужно запомнить команду
	
Файл можно переиспользовать
Когда использовать --set:

    Быстрое тестирование одного параметра
    Переопределение 1-2 значений при установке
    CI/CD пайплайны с динамическими параметрами (версия образа)

Когда использовать -f:

    Настройка окружений (dev/staging/prod)
    Сложная конфигурация с множеством параметров
    Командная работа (файл в Git)
    Воспроизводимые деплои

Пример комбинации:
helm install myapp ./chart -f values-prod.yaml --set image.tag=v1.2.3
Вопрос 7: Пакетирование — зачем helm package?
Ответ:
Зачем нужна команда:

    Создаёт .tgz архив чарта — единый артефакт для распространения
    Версионирует чарт (семантическое версионирование)
    Позволяет распространять чарт без исходников

Сценарии использования .tgz:

    Helm Repository: Публикация чарта в репозитории (ChartMuseum, Nexus, S3). Пользователи устанавливают через helm repo add + helm install.
    CI/CD артефакты: Чарт собирается в пайплайне, сохраняется как артефакт (Artifactory, GitHub Packages), затем разворачивается в разных окружениях.
    Air-gapped среды: В изолированных сетях без доступа к интернету/репозиториям .tgz передаётся вручную.
    Контроль версий: Фиксация конкретной версии чарта для аудита и отката.
    Распространение между командами: Отправка чарта другой команде без доступа к Git-репозиторию.

Пример рабочего процесса:
# Разработчик создаёт чарт
helm package myapp-chart --version 1.0.0

# Загружает в репозиторий
helm push myapp-chart-1.0.0.tgz oci://registry.example.com/charts

# Пользователь устанавливает
helm install myapp oci://registry.example.com/charts/myapp-chart --version 1.0.0
Выводы

    Helm — мощный инструмент управления приложениями в Kubernetes, реализующий принцип DRY через шаблоны Go Template.
    Values-файлы позволяют использовать один чарт для разных окружений (dev/prod) с разными параметрами.
    Rollback — критически важная функция для быстрого восстановления при сбоях деплоя.
    Собственный чарт мониторинга легче и прозрачнее, чем kube-prometheus-stack, и подходит для учебных/ограниченных сред.
    Kubernetes DNS обеспечивает стабильную адресацию сервисов независимо от IP подов.
    Resource Limits защищают кластер от каскадных сбоев при нехватке памяти.

Кластер готов к эксплуатации с полноценным мониторингом!
