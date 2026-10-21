 Отчёт по заданию B1: Создание собственной Ansible-коллекции

### 1. Что такое Ansible-коллекция и чем она отличается от роли?

**Ansible-коллекция** — это формат дистрибуции контента, который включает:
- Несколько ролей
- Модули (Python-код)
- Плагины (filter, lookup, callback)
- Плейбуки
- Документацию
- Тесты

**Роль** — это структура каталогов для организации задач, переменных, шаблонов и handlers в рамках одного проекта.

| Характеристика | Роль | Коллекция |
|----------------|------|-----------|
| **Структура** | Папка с tasks/, templates/, etc. | Пакет с galaxy.yml, roles/, plugins/ |
| **Пространство имён** | Нет (только имя) | Да (namespace.name) |
| **Версионирование** | Через Git | SemVer в galaxy.yml |
| **Распространение** | Копирование папок | ansible-galaxy install |
| **Зависимости** | Ручное управление | Автоматическое через galaxy.yml |

**Аналогия:** Роль — это функция, коллекция — это библиотека/пакет.

### 2. Что такое FQCN (Fully Qualified Collection Name)?
**FQCN** — полное квалифицированное имя ресурса в формате:
namespace.collection_name.resource_type.resource_name


Примеры:
- Роль: `mystudent.sysadmin.nginx`
- Модуль: `ansible.builtin.apt`
- Плагин: `community.general.docker_container`

**Зачем нужен FQCN:**
- Предотвращает конфликты имён (у разных авторов могут быть роли с одинаковым именем)
- Явно указывает источник ресурса
- Требуется в Ansible 2.10+ для большинства модулей

Пример использования:
```yaml
- hosts: web
  collections:
    - mystudent.sysadmin
  
  tasks:
    - name: Deploy nginx
      mystudent.sysadmin.nginx:  # FQCN роли
        port: 8080

3. Зачем нужен файл galaxy.yml?
galaxy.yml — это файл метаданных коллекции, который содержит:
Обязательные поля:

    namespace — пространство имён (обычно имя компании/автора)
    name — имя коллекции
    version — версия по SemVer (1.0.0)

Рекомендуемые поля:

    authors — авторы
    description — описание
    license — лицензия (GPL-3.0, MIT, etc.)
    tags — теги для поиска
    dependencies — зависимости от других коллекций
    repository, documentation, homepage — ссылки

Без galaxy.yml невозможно:

    Собрать коллекцию (ansible-galaxy collection build)
    Опубликовать на Ansible Galaxy
    Установить через ansible-galaxy collection install

4. Как бы вы опубликовали коллекцию на Ansible Galaxy?
Шаги публикации:

    Создать аккаунт на galaxy.ansible.com
     или в Automation Hub
    Сгенерировать API-токен:
        Preferences → API Keys → Create New Key
        Скопировать токен
    Собрать коллекцию:   ansible-galaxy collection build mystudent/sysadmin
Опубликовать:
   ansible-galaxy collection publish mystudent-sysadmin-1.0.0.tar.gz \
     --api-key=ВАШ_API_КЛЮЧ

Проверить
   ansible-galaxy collection install mystudent.sysadmin
Для приватных коллекций: Использовать Ansible Automation Hub или приватный Galaxy-сервер.
5. Почему важно версионировать коллекции?
Причины версионирования (SemVer):

    Воспроизводимость: Проекты фиксируют версию ==1.0.0 и гарантированно работают
    Контроль изменений: Breaking changes только в мажорных версиях (2.0.0)
    Безопасность: Можно быстро откатиться при проблемах
    Зависимости: Другие коллекции могут указывать зависимости >=1.0.0,<2.0.0
    CI/CD: Автоматическое тестирование разных версий

SemVer формат: MAJOR.MINOR.PATCH

    MAJOR — breaking changes (несовместимые изменения)
    MINOR — новые функции (обратно совместимые)
    PATCH — багфиксы

Пример: Если в версии 2.0.0 вы изменили имя переменной в роли, проекты с version: 1.0.0 продолжат работать.
