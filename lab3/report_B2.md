# Отчёт по заданию B2: Тестирование ролей через Molecule


1. Что такое Molecule и зачем он нужен?

Molecule — фреймворк для автоматического тестирования Ansible-ролей. Он создаёт временные контейнеры или ВМ (Docker, Vagrant, EC2 и т. п.), применяет к ним тестируемую роль, запускает проверки (testinfra, goss, inspec) и затем удаляет тестовые ресурсы.

Зачем:

качество — роль проверяется не только на машине разработчика;

регрессионное тестирование — изменения не ломают то, что уже работало;

идемпотентность — повторный запуск не должен вносить изменений.

Типовой сценарий включает этапы: создание (create), применение роли (converge), проверка идемпотентности (idempotence), дополнительные действия (side_effect), тесты (verify), очистка (cleanup) и удаление (destroy). Для отладки этапы можно запускать по отдельности:

bash
molecule create    # только создать
molecule converge  # применить роль
molecule verify    # запустить тесты
molecule destroy   # удалить
2. Что такое testinfra и как он работает?

Testinfra — Python-библиотека для тестирования инфраструктуры в стиле pytest.

Как работает:

Подключается к хосту (SSH, Docker API, paramiko).

Даёт API для проверки состояния системы.

Выполняет assertions в стиле pytest.

Примеры проверок:

python
def test_nginx_installed(host):
    nginx = host.package("nginx")
    assert nginx.is_installed

def test_nginx_running(host):
    nginx = host.service("nginx")
    assert nginx.is_running
    assert nginx.is_enabled

def test_port_80(host):
    assert host.socket("tcp://0.0.0.0:80").is_listening

def test_file_exists(host):
    f = host.file("/etc/nginx/nginx.conf")
    assert f.exists
    assert f.user == "root"
    assert f.mode == 0o644
Преимущества: простой Python-синтаксис, интеграция с pytest (отчёты, фикстуры), поддержка разных бэкендов (Docker, SSH, локальный).

3. Почему важно тестировать роль на разных ОС (Ubuntu, Debian)?

Потому что между дистрибутивами есть различия, которые ломают «универсальные» роли:

пакетные менеджеры: apt (Ubuntu/Debian), yum/dnf (CentOS/RHEL), apk (Alpine);

пути к конфигам: могут отличаться в зависимости от дистрибутива;

имена сервисов: nginx или httpd (CentOS);

версии systemd: Ubuntu 24.04 — 255, Debian 12 и CentOS 9 — 252;

версии пакетов: nginx 1.24 в Ubuntu 24.04, 1.22 в Debian 12.

Best practice: тестировать минимум на 2–3 дистрибутивах до публикации.

4. Как интегрировать Molecule в GitLab CI?

Пример .gitlab-ci.yml:

yaml
stages:
  - test
  - deploy

test_role:
  stage: test
  image: python:3.12
  services:
    - docker:24-dind  # Docker-in-Docker для контейнеров
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
      when: manual

deploy:
  stage: deploy
  script:
    - ansible-playbook deploy.yml
  only:
    - main
Ключевые моменты:

использовать docker:dind для запуска контейнеров внутри CI;

кэшировать pip-пакеты для ускорения;

запускать тесты только при изменениях в роли (changes:);

применять rules: для условного запуска.

Альтернатива — GitHub Actions с исполнителем ubuntu-latest и Docker.
