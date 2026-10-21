Отчёт B1: include/import 
Выполнил: Кучин Арсений
Дата: 28 сентября 2026

1. Чем include_tasks отличается от import_tasks?

import_tasks подставляется на этапе разбора плейбука — статически. Поэтому теги и условия родителя на вложенные задачи распространяются. include_tasks подгружается уже во время выполнения — динамически, и теги родителя на него не переносятся.

2. Чем include_role отличается от import_role?

import_role — статический вариант: роли видны заранее (например, в --list-tasks), теги наследуются. include_role — динамический: позволяет вычислять имя роли из переменных уже в ходе выполнения.

3. Когда использовать include, а когда import?

import — для базовой структуры плейбука и там, где важно наследование тегов. include — для динамики: например, когда роль нужно подключить только при определённом значении переменной.

4. Как работают --tags и --skip-tags?

--tags install — выполнить только задачи с тегом install.

--skip-tags hardening — выполнить всё, кроме задач с тегом hardening.

5. Почему hardening применился на node2, но не на node1?

В full-deploy.yml у роли hardening стоит условие:

yaml
when: app_env in ["staging", "production"]
У node1 окружение — dev, условие ложно, поэтому роль пропускается. У node2 условие выполняется, и hardening отрабатывает.

6. Что делает tags: [always]?

Задача с тегом always выполняется в любом случае — даже если запуск идёт с --tags, который её не включает. Удобно для логирования, инициализации и подобных служебных шагов.



when: app_env in ["staging", "production"]

У node1 (dev) это условие ложно.
6. Что делает tags: [always]?
Задача с этим тегом будет выполняться всегда, даже если запущен плейбук с фильтром --tags, который её не включает (полезно для логов или инициализации).

Результаты выполнения

$ ansible-playbook playbooks/full-deploy.yml

PLAY RECAP *********************************************************************
node1    : ok=15  changed=1  unreachable=0  failed=0
node2    : ok=19  changed=4  unreachable=0  failed=0

$ ssh student@node1 "systemctl is-active fail2ban"
inactive

$ ssh student@node2 "systemctl is-active fail2ban"
active

$ ansible-playbook playbooks/full-deploy.yml --tags install

PLAY RECAP *********************************************************************
node1    : ok=2  changed=0  unreachable=0  failed=0
node2    : ok=2  changed=0  unreachable=0  failed=0

