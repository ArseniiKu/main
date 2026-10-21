# Отчёт A2: Переменные, условия и циклы


## Вопросы и ответы

1. Приоритет переменных в Ansible (от низшего к высшему, минимум 5 уровней)

Значения по умолчанию для роли (roles/webapp/defaults/main.yml) — самый низкий приоритет.

Переменные группы из инвентаря (inventory/group_vars/web.yml).

Переменные конкретного хоста (inventory/host_vars/node1.yml).

Переменные, заданные в самом плейбуке (vars:).

Extra vars (-e в командной строке) — перекрывают всё остальное.

2. Чем host_vars отличаются от group_vars?

group_vars задают переменные для целой группы хостов — например, для всех веб-серверов сразу. host_vars действуют точечно: только на один хост, и обычно используются, чтобы переопределить общее значение или добавить что-то уникальное (скажем, только для node1).

3. Что делает when? Два примера из работы.

when включает задачу по условию — если оно ложно, задача пропускается.

Пример 1 — debug-инструменты только в разработке:

yaml
- name: Install debug tools
  apt:
    name: [htop, strace, tcpdump]
    state: present
  when: app_env == "development"
Пример 2 — заголовок добавляется, только если переменная задана:

yaml
- name: Добавить пользовательскую строку заголовка
  lineinfile:
    path: /etc/nginx/nginx.conf
    line: "add_header {{ custom_header }}"
  when: custom_header is defined
4. Чем loop отличается от with_items?

loop — актуальный и рекомендуемый способ перебора (с Ansible 2.6+). with_items — устаревший синтаксис, который внутри всё равно приводится к loop. Функционально близки, но использовать стоит loop.

5. Зачем нужен loop_control.label?

Чтобы вывод в консоль был читаемым. Без него на каждой итерации печатается весь словарь item, с label — только нужное поле:

yaml
loop_control:
  label: "{{ item.username }}"
6. Что делают --tags и --skip-tags?

--tags info — выполнить только задачи с тегом info.

--skip-tags hardening — выполнить всё, кроме задач с тегом hardening.

7. Как добавить третье окружение (production)?

В hosts.ini добавить группу [production] с хостами.

Создать inventory/group_vars/production.yml:

yaml
app_env: production
enable_ssl: true
enable_auth: true
nginx_worker_connections: 4096
log_level: warn
Дальше запускать плейбук с ограничением на эту группу (-l production) или через соответствующий inventory.

Результаты выполнения

$ ansible-playbook playbooks/deploy-env.yml

PLAY RECAP *********************************************************************
node1    : ok=17  changed=4  unreachable=0  failed=0
node2    : ok=16  changed=4  unreachable=0  failed=0

$ curl -s http://node1:8080 | grep "Environment"
<p><strong>Environment:</strong> development</p>

$ curl -s http://node2:8080 | grep "Environment"
<p><strong>Environment:</strong> staging</p>

$ ssh student@node1 "getent passwd | grep -E 'alice|bob|charlie|diana|eve'"
alice:x:1002:1004:Alice Smith:/home/alice:/bin/bash
bob:x:1003:1005:Bob Johnson:/home/bob:/bin/bash
charlie:x:1004:1006:Charlie Brown:/home/charlie:/bin/bash
diana:x:1005:1007:Diana Prince:/home/diana:/bin/bash
eve:x:1006:1008:Eve Adams:/home/eve:/bin/bash
