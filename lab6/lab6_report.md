# Отчет по лабораторной работе №6
## Развертывание кластера K3s и приложения Nginx


## Цель работы
Развертывание кластера Kubernetes на базе K3s в среде LXD, настройка архитектуры Master-Worker, деплой и масштабирование веб-приложения Nginx.

---

## Архитектура инфраструктуры

### Узлы кластера:
- **Master node (Control Plane):** ubuntuu (хостовая машина)
  - IP: 10.3.51.1
  - Роль: управление кластером, API server, scheduler, controller-manager
  
- **Worker nodes:**
  - node1 (10.3.51.99) - выполнение рабочих нагрузок
  - node2 (10.3.51.118) - выполнение рабочих нагрузок

### Сетевая конфигурация:
- LXD bridge (lxdbr0): 10.3.51.0/24
- CNI: Flannel (VXLAN backend)
- Pod CIDR: 10.42.0.0/16
- Service CIDR: 10.43.0.0/16

---

## Ход выполнения

### Шаг 1: Подготовка инфраструктуры

```bash
# Создание LXD контейнеров
lxc launch ubuntu:24.04 ctrl
lxc launch ubuntu:24.04 node1
lxc launch ubuntu:24.04 node2

# Настройка ресурсов
lxc config set ctrl limits.memory 3GiB
lxc config set node1 limits.memory 1.5GiB
lxc config set node2 limits.memory 1.5GiB

# Загрузка модулей ядра на хосте
sudo modprobe br_netfilter
sudo modprobe overlay
# Установка на хостовой машине
curl -sfL https://get.k3s.io | sudo sh -s - \
  --disable=traefik \
  --disable=servicelb \
  --disable=metrics-server \
  --tls-san=10.3.51.1 \
  --write-kubeconfig-mode=644

# Настройка kubectl
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(whoami):$(whoami) ~/.kube/config
chmod 600 ~/.kube/config
sed -i 's|127.0.0.1|10.3.51.1|g' ~/.kube/config
# Получение токена
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)

# На node1 и node2
export K3S_URL=https://10.3.51.1:6443
export K3S_TOKEN=$TOKEN
curl -sfL https://get.k3s.io | sh -
# Применение манифестов
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

# Проверка
kubectl get nodes
kubectl get pods -o wide
kubectl get svc

---

### Часть 5: Добавление ответов на вопросы (ЧАСТЬ 3 из 4)

```bash
# Добавляем ответы на вопросы
cat >> lab6_report.md << 'EOF'

---

## Ответы на контрольные вопросы

### Вопрос 1: Почему в нашей архитектуре `ctrl` является Master'ом, а не `node1`?

**Ответ:**

Выделение отдельного узла `ctrl` (control plane) реализует принцип **разделения ответственности** (separation of concerns):

1. **Стабильность и надежность управления:**
   - Master-узел хранит состояние кластера в etcd/kine
   - API server работает изолированно от рабочих нагрузок
   - При падении worker-узла управление кластером не прерывается

2. **Удобство автоматизации (Ansible/Terraform):**
   - **Единая точка входа:** `ctrl` — стабильный endpoint для управления
   - **Предсказуемость:** Скрипты всегда знают, где API server
   - **Безопасность:** Можно настроить строгие правила доступа только к `ctrl`

3. **Ресурсная изоляция:**
   - Рабочие нагрузки не конкурируют за ресурсы с компонентами управления
   - Это предотвращает ситуации, когда приложение "съедает" всю память/CPU

---

### Вопрос 2: Что произойдет при обращении к `http://node2:30080`, если под на `ctrl` и `node1`?

**Ответ:**

Трафик будет **успешно доставлен** к поду с Nginx благодаря **kube-proxy**.

**Механизм работы:**

1. **kube-proxy на каждом узле** настраивает правила iptables/IPVS
2. При запросе на `node2:30080`, kube-proxy перехватывает трафик
3. Выполняется **DNAT** (преобразование адреса):
   - `node2:30080` → `ClusterIP:80` → `Pod_IP:80` (на ctrl или node1)
4. CNI (Flannel) обеспечивает маршрутизацию между узлами

**Результат:** Можно обращаться к ЛЮБОМУ узлу кластера — трафик автоматически перенаправится к нужному поду.

---

### Вопрос 3: Зачем ограничили `resources.limits.memory: "128Mi"`?

**Ответ:**

Ограничение ресурсов критически важно для **стабильности кластера**.

**Причины:**

1. **Защита от "шумного соседа":**
   - Без лимитов одно приложение может монополизировать все ресурсы
   - Другие поды начнут испытывать нехватку памяти/CPU

2. **Предотвращение каскадных сбоев:**
   - Если приложение потребит всю память → сработает **OOM Killer**
   - Ядро может убить критически важный процесс (kubelet, containerd)
   - Это приведет к отказу всего узла

3. **Особенности LXD:**
   - Контейнеры делят **одно ядро хоста** (нет полной изоляции как в VM)
   - Если один контейнер исчерпает память — пострадают ВСЕ

**Что было бы без лимитов:**
Nginx начинает потреблять 500MB, 1GB, 2GB...
На узле с 1.5GB заканчивается память
OOM Killer убивает процессы:

    Вариант А: убивает pod nginx (циклический перезапуск)
    Вариант Б: убивает kubelet → узел выпадает из кластера
    Вариант В: убивает containerd → ВСЕ поды падают

**Почему 128Mi:** Nginx — легковесный сервер, ему достаточно 64-128MB для статического контента.

---

### Вопрос 4: Разница между `kubectl get pods` и `kubectl describe pod`?

**Ответ:**

| Характеристика | `kubectl get pods` | `kubectl describe pod` |
|----------------|-------------------|----------------------|
| **Уровень** | Высокоуровневый обзор | Детальная информация |
| **Объект** | Все поды | Один конкретный под |
| **Формат** | Таблица | Подробный текст |
| **Скорость** | Быстро (<1 сек) | Медленнее (2-5 сек) |
| **Events** | Нет | Да (критически важно!) |

**`kubectl get pods` — когда использовать:**
- Быстрая проверка: "все ли поды Running?"
- Мониторинг состояния кластера
- Поиск проблемных подов

**`kubectl describe pod <name>` — когда использовать:**
- Под в статусе CrashLoopBackOff, ImagePullBackOff, Pending
- Нужно понять ПРИЧИНУ сбоя
- Проверка конфигурации (ресурсы, volumes, env)
- Анализ событий (раздел **Events** покажет что происходило)

**Пример:**
```bash
# Быстрый обзор
kubectl get pods
# NAME                    STATUS
# nginx-abc12             Running
# nginx-xyz34             CrashLoopBackOff  ← Проблема!

# Детальная диагностика
kubectl describe pod nginx-xyz34
# Events:
#   Warning  BackOff  Back-off restarting failed container
#   Error    OOMKilled  Container exceeded memory limit
#   ← Вот причина!
Выводы

    ✅ Успешно развернут кластер K3s с архитектурой Master-Worker
    ✅ Продемонстрированы механизмы Kubernetes:
        Deployment — управление состоянием
        Service (NodePort) — балансировка нагрузки
        Resource Limits — защита стабильности
    ✅ Понята работа kube-proxy — доступность сервисов на любом узле
    ✅ Освоены инструменты диагностики: get vs describe

Кластер готов к эксплуатации!
