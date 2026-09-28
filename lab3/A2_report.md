# Отчёт A2: Переменные, условия и циклы

**Выполнил:** Кучин Арсений
**Дата:** 28 сентября 2026

---

## Вопросы и ответы

### 1. Объясните приоритет переменных в Ansible (от низшего к высшему, минимум 5 уровней)

1. **role defaults** (`roles/webapp/defaults/main.yml`)
2. **inventory group_vars** (`inventory/group_vars/web.yml`)
3. **inventory host_vars** (`inventory/host_vars/node1.yml`)
4. **playbook vars**
5. **extra vars** (`-e` в командной строке)

### 2. В чём разница между `host_vars` и `group_vars`?

- **`group_vars`** — применяет переменные ко всей группе хостов (например, ко всем web-серверам)
- **`host_vars`** — переопределяет или добавляет переменные для одного конкретного хоста (например, только для node1)

### 3. Что делает `when` в задачах? Приведите 2 примера из вашей работы.

`when` — условное выполнение задачи.

**Пример 1:** Установка debug-инструментов только в development:
```yaml
- name: Install debug tools
  apt:
    name: [htop, strace, tcpdump]
    state: present
  when: app_env == "development"
```
Пример 2: Добавление заголовка, только если он определён:

- name: Add custom header
  lineinfile:
    path: /etc/nginx/nginx.conf
    line: "add_header {{ custom_header }}"
  when: custom_header is defined
  
4. В чём разница между loop и with_items?
loop — современный, рекомендуемый способ итерации (Ansible 2.6+)
with_items — устаревший синтаксис, под капотом преобразуется в loop
5. Зачем нужен loop_control.label?
Делает вывод консоли читаемым. Вместо вывода всего словаря при каждой итерации показывает только имя:

loop_control:
  label: "{{ item.username }}"

  6. Что делают --tags и --skip-tags при запуске плейбука?
--tags info — выполнить только задачи с тегом info
--skip-tags hardening — выполнить всё, КРОМЕ задач с тегом hardening
7. Как бы вы добавили третье окружение (production)?
Добавить группу [production] в hosts.ini
Создать файл inventory/group_vars/production.yml:
app_env: production
enable_ssl: true
enable_auth: true
nginx_worker_connections: 4096
log_level: warn

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
