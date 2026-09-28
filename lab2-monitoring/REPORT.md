# Отчет по лабораторной работе №2

**Дата:** [28.09.26]
**Студент:** [Арсений Кучин]

## Тема: Мониторинг инфраструктуры (Prometheus + Grafana)

## Цель
Развернуть систему мониторинга на базе Prometheus + Grafana с использованием Ansible.

## Выполненные задачи
- ✅ Настроена инфраструктура из 3 узлов (node1, node2, mon)
- ✅ Создан Ansible playbook для автоматизации
- ✅ Развернуты: Nginx, Prometheus Node Exporter, Prometheus Server, Grafana
- ✅ Импортирован дашборд Node Exporter Full (ID: 1860)
- ✅ Проверена идемпотентность

## PLAY RECAP
mon    : ok=19  changed=4  unreachable=0  failed=0
node1  : ok=3   changed=0  unreachable=0  failed=0
node2  : ok=3   changed=0  unreachable=0  failed=0

## Вывод
Система мониторинга успешно развёрнута. Все сервисы работают корректно.
