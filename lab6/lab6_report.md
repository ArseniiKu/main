Отчёт по лабораторной работе №6

Развёртывание кластера K3s и приложения Nginx

Цель работы

Развернуть кластер Kubernetes на базе K3s в среде LXD, реализовать архитектуру Master–Worker, выполнить деплой и масштабирование веб-приложения Nginx.

Архитектура инфраструктуры
Узлы кластера:

Master node (Control Plane): ubuntuu (хостовая машина)

IP: 10.3.51.1

Роль: управление кластером, API server, scheduler, controller-manager

Рабочие узлы:

node1 (10.3.51.99) — выполнение рабочих нагрузок

node2 (10.3.51.118) — выполнение рабочих нагрузок

Сетевая конфигурация:

Мост LXD (lxdbr0): 10.3.51.0/24

CNI: Flannel (серверная часть VXLAN)

CIDR модулей: 10.42.0.0/16

CIDR сервисов: 10.43.0.0/16

Ход выполнения
Шаг 1. Подготовка инфраструктуры
bash
# Создание контейнеров LXD
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
Шаг 2. Установка K3s на хост-машину
bash
curl -sfL https://get.k3s.io | sudo sh -s - \
  --disable=traefik \
  --disable=servicelb \
  --disable=metrics-server \
  --tls-san=10.3.51.1 \
  --write-kubeconfig-mode=644
Шаг 3. Настройка kubectl
bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(whoami):$(whoami) ~/.kube/config
chmod 600 ~/.kube/config
sed -i 's|127.0.0.1|10.3.51.1|g' ~/.kube/config
Шаг 4. Подключение рабочих узлов
bash
# Получение токена
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)

# На node1 и node2
export K3S_URL=https://10.3.51.1:6443
export K3S_TOKEN=$TOKEN
curl -sfL https://get.k3s.io | sh -
Шаг 5. Деплой приложения
bash
# Применение манифестов
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

# Проверка
kubectl get nodes
kubectl get pods -o wide
kubectl get svc
Ответы на контрольные вопросы
Вопрос 1. Почему в данной архитектуре ctrl выполняет роль Master, а не node1?
Роль управляющего узла целенаправленно закреплена за ctrl, что соответствует принципу разделения ответственности. Причины:

Устойчивость управления. На Master-узле размещаются etcd/kine и API server. Их изоляция от рабочих нагрузок гарантирует, что сбой или перегрузка worker-узла не нарушит управление кластером.

Удобство автоматизации. ctrl выступает единой стабильной точкой входа для Ansible/Terraform и прочих инструментов: адрес API server всегда предсказуем, а политики доступа можно ограничить одним узлом.

Изоляция ресурсов. Компоненты управления не конкурируют за память и CPU с приложениями, что снижает риск деградации control plane при пиковых нагрузках.

Иными словами, node1 — рядовой исполнитель, а ctrl — выделенный центр управления.

Вопрос 2. Что произойдёт при обращении к http://node2:30080, если под запущен на ctrl или node1?
Запрос будет успешно обслужен: благодаря kube-proxy и CNI трафик дойдёт до пода независимо от того, на каком узле он размещён.

Механизм:

kube-proxy на каждом узле поддерживает правила iptables/IPVS для сервисов.

Запрос на node2:30080 перехватывается и подвергается DNAT: node2:30080 → ClusterIP:80 → Pod_IP:80.

Flannel обеспечивает маршрутизацию пакетов между узлами.

Таким образом, NodePort делает сервис доступным через любой узел кластера — обращение к node2 не требует, чтобы под находился именно на node2.

Вопрос 3. С какой целью задан resources.limits.memory: "128Mi"?
Лимит памяти — это механизм защиты стабильности кластера, а не формальность.

Защита от «шумного соседа». Без лимитов одно приложение способно занять всю доступную память и лишить ресурсов остальные поды.

Предотвращение каскадных отказов. При исчерпании памяти срабатывает OOM Killer, который может завершить не только под Nginx, но и kubelet или containerd — вплоть до выпадения узла из кластера.

Специфика LXD. Контейнеры используют общее ядро хоста, поэтому исчерпание памяти одним контейнером отражается на всех.

Без ограничения сценарий развивался бы так: рост потребления Nginx → нехватка памяти на узле с 1.5 GiB → OOM Killer завершает либо под (циклические перезапуски), либо kubelet (узел теряет связь с кластером), либо containerd (падают все поды).

Значение 128Mi выбрано потому, что Nginx — лёгкий сервер, и для отдачи статического контента ему достаточно 64–128 MB.

Вопрос 4. Чем отличаются kubectl get pods и kubectl describe pod?
Критерий	kubectl get pods	kubectl describe pod
Назначение	Обзор состояния	Детальная диагностика
Охват	Все поды	Один под
Формат	Таблица	Подробный текст
Быстродействие	Высокое	Ниже
События (Events)	Не показывает	Показывает
kubectl get pods применяется для быстрой проверки: все ли поды в состоянии Running, нет ли подов в ошибке, какова общая картина кластера.

kubectl describe pod <name> применяется, когда под находится в CrashLoopBackOff, ImagePullBackOff или Pending, и нужно установить причину: проверить конфигурацию, ресурсы, тома, переменные окружения и, главное, раздел Events.

Пример:

bash
# Быстрый обзор
kubectl get pods
# NAME           STATUS
# nginx-abc12    Running
# nginx-xyz34    CrashLoopBackOff   ← проблема

# Детальная диагностика
kubectl describe pod nginx-xyz34
# Events:
#   Warning  BackOff   restarting failed container
#   Warning  OOMKilled container exceeded memory limit
Выводы
Кластер K3s с архитектурой Master–Worker успешно развёрнут.

Отработаны ключевые механизмы Kubernetes: Deployment (управление состоянием), Service типа NodePort (балансировка), Resource Limits (защита стабильности).

Подтверждено поведение kube-proxy: сервис доступен через любой узел кластера.

Освоены инструменты диагностики: сопоставление get и describe.

Кластер готов к эксплуатации.
