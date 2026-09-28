Отчёт B1: include/import 
Выполнил: Кучин Арсений
Дата: 28 сентября 2026

Вопросы и ответы
1. В чём разница между include_tasks и import_tasks?
import_tasks — обрабатывается на этапе парсинга плейбука (статически). Теги и условия родителя наследуются.
include_tasks — выполняется динамически во время выполнения плейбука. Теги родителя на него не влияют.
2. В чём разница между include_role и import_role?
import_role — статичный (роли видны при --list-tasks), теги наследуются
include_role — динамический (позволяет использовать переменные, вычисленные во время выполнения, для имени роли)
3. Когда использовать include, а когда import?
import — для основной структуры и когда нужно наследование тегов
include — для динамической логики (например, запуск роли только если переменная равна X)
4. Как работают --tags и --skip-tags?
--tags install — выполнит только задачи с этим тегом
--skip-tags hardening — выполнит всё, КРОМЕ задач с этим тегом
5. Почему hardening применился на node2, но не на node1?
Потому что в full-deploy.yml для роли hardening указано условие:

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

