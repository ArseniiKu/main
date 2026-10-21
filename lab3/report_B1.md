 Отчёт по заданию B1: Создание собственной Ansible-коллекции

1. Что такое Ansible-коллекция и чем она отличается от роли?

Коллекция — это формат дистрибуции контента: в один пакет могут входить несколько ролей, модули (Python-код), плагины (filter, lookup, callback), плейбуки, документация и тесты. Роль же — просто структура каталогов для организации задач, переменных, шаблонов и обработчиков внутри одного проекта.

Критерий	Роль	Коллекция
Структура	Папка с tasks/, templates/ и т. д.	Пакет с galaxy.yml, roles/, plugins/
Пространство имён	Нет, только имя	Есть (namespace.name)
Версионирование	Через Git	SemVer в galaxy.yml
Распространение	Копирование папок	ansible-galaxy install
Зависимости	Управляются вручную	Автоматически через galaxy.yml
Аналогия: роль — это функция, коллекция — библиотека или пакет.

2. Что такое FQCN?

FQCN (fully qualified collection name) — полное имя ресурса в формате namespace.collection_name.resource_type.resource_name.

Примеры:

роль: mystudent.sysadmin.nginx

модуль: ansible.builtin.apt

плагин: community.general.docker_container

Зачем нужен FQCN:

исключает конфликты имён у разных авторов;

явно указывает, откуда взят ресурс;

обязателен в Ansible 2.10+ для большинства модулей.

Пример:

yaml
- hosts: web
  collections:
    - mystudent.sysadmin

  tasks:
    - name: Deploy nginx
      mystudent.sysadmin.nginx:  # полное имя роли
        port: 8080
3. Зачем нужен galaxy.yml?

Это файл метаданных коллекции.

Обязательные поля:

namespace — пространство имён (компания/автор);

name — имя коллекции;

version — версия по SemVer (например, 1.0.0).

Рекомендуемые поля:

authors, description, license;

tags — для поиска;

dependencies — зависимости от других коллекций;

repository, documentation, homepage — ссылки.

Без galaxy.yml нельзя собрать коллекцию (ansible-galaxy collection build), опубликовать её на Ansible Galaxy и установить через ansible-galaxy collection install.

4. Как опубликовать коллекцию на Ansible Galaxy?

Зарегистрироваться на galaxy.ansible.com (или в Automation Hub).

Сгенерировать API-токен: Настройки → Ключи API → Создать новый ключ.

Собрать коллекцию:

bash
ansible-galaxy collection build mystudent/sysadmin
Опубликовать:

bash
ansible-galaxy collection publish mystudent-sysadmin-1.0.0.tar.gz \
    --api-key=ВАШ_API_КЛЮЧ
Проверить установку:

bash
ansible-galaxy collection install mystudent.sysadmin
Для приватных коллекций используется Ansible Automation Hub или собственный Galaxy-сервер.

5. Почему важно версионировать коллекции?

Версионирование по SemVer даёт:

воспроизводимость — проект фиксирует ==1.0.0 и работает предсказуемо;

контроль изменений — несовместимые правки только в мажорной версии (2.0.0);

безопасность — при проблемах можно быстро откатиться;

управление зависимостями — другие коллекции указывают, например, >=1.0.0,<2.0.0;

CI/CD — можно автоматически тестировать разные версии.

Формат SemVer — MAJOR.MINOR.PATCH:

MAJOR — несовместимые изменения;

MINOR — новые функции с обратной совместимостью;

PATCH — исправления ошибок.

Пример: если в 2.0.0 переименована переменная роли, проекты с version: 1.0.0 продолжат работать.


