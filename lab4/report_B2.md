# Отчёт по заданию B2: Тестирование ролей через Molecule

### 1. Что такое Molecule и зачем он нужен?

**Molecule** — это фреймворк для автоматического тестирования Ansible-ролей. Он:
- Создаёт временные контейнеры/VM (Docker, Vagrant, EC2, etc.)
- Применяет тестируемую роль
- Запускает тесты (testinfra, goss, inspec)
- Удаляет тестовые ресурсы

**Зачем нужен:**
- **Гарантия качества:** Роль работает не только на машине разработчика
- **Регрессионное тестирование:** Изменения не ломают существую…тестируемой роли к контейнерам
7. **idempotence** — проверка идемпотентности (повторный запуск без изменений)
8. **side_effect** — дополнительные действия (опционально)
9. **verify** — запуск тестов (testinfra, goss)
10. **cleanup** — очистка после тестов
11. **destroy** — удаление контейнеров/VM

**Для отладки можно запускать по отдельности:**
```bash
molecule create      # только создать
molecule converge    # применить роль
molecule verify      # запустить тесты
molecule destroy     # удалить

. Что такое testinfra и как он работает?
Testinfra — это Python-библиотека для тестирования инфраструктуры в стиле pytest.
Как работает:

    Подключается к хосту (через SSH, Docker API, paramiko)
    Предоставляет API для проверки состояния системы
    Выполняет assertions (утверждения) в стиле pytest

Примеры проверок:
def test_nginx_installed(host):
    nginx = host.package("nginx")
    assert nginx.is_installed  # Проверка установки пакета

def test_nginx_running(host):
    nginx = host.service("nginx")
    assert nginx.is_running    # Проверка запущенного сервиса
    assert nginx.is_enabled    # Проверка автозагрузки

def test_port_80(host):
    assert host.socket("tcp://0.0.0.0:80").is_listening  # Проверка порта

def test_file_exists(host):
    f = host.file("/etc/nginx/nginx.conf")
    assert f.exists
    assert f.user == "root"
    assert f.mode == 0o644
Преимущества:

    Простой Python-синтаксис
    Интеграция с pytest (отчёты, fixtures)
    Поддержка множества бэкендов (Docker, SSH, local)

4. Почему важно тестировать роль на разных ОС (Ubuntu, Debian)?
Причины мультиплатформенного тестирования:

    Разные пакетные менеджеры:
        Ubuntu/Debian: apt
        CentOS/RHEL: yum/dnf
        Alpine: apk
    Разные пути к конфигам:
        Ubuntu: /etc/nginx/nginx.conf
        CentOS: /etc/nginx/nginx.conf (может отличаться)
        Alpine: /etc/nginx/nginx.conf
    Разные имена сервисов:
        Ubuntu: nginx
        CentOS: nginx или httpd
    Разные версии systemd:
        Ubuntu 24.04: systemd 255
        Debian 12: systemd 252
        CentOS 9: systemd 252
    Разные версии пакетов:
        Ubuntu 24.04: nginx 1.24
        Debian 12: nginx 1.22

Best practice: Тестировать минимум на 2-3 дистрибутивах перед публикацией.
5. Как бы вы интегрировали Molecule в GitLab CI?
Пример .gitlab-ci.yml:

stages:
  - test
  - deploy

test_role:
  stage: test
  image: python:3.12
  services:
    - docker:24-dind  # Docker-in-Docker для запуска контейнеров
  variables:
    DOCKER_HOST: tcp://docker:2375
    DOCKER_TLS_CERTDIR: ""
  before_script:
    - pip install molecule molecule-plugins[docker] testinfra ansible-lint
    - ansible-galaxy collection install community.docker
  script:
    - cd roles/nginx
    - molecule test
  rules:
    - changes:
        - roles/nginx/**/*
    - when: manual  # Запуск вручную или при изменениях

deploy:
  stage: deploy
  script:
    - ansible-playbook deploy.yml
  only:
    - main

лючевые моменты:

    Использовать docker:dind (Docker-in-Docker) для запуска контейнеров внутри CI
    Кэшировать pip-пакеты для ускорения
    Запускать тесты только при изменениях в роли (changes:)
    Использовать rules: для условного запуска

Альтернатива: GitHub Actions с ubuntu-latest runner и Docker.
