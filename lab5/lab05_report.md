# Отчёт по лабораторной работе №5

## Структура проекта


## Часть A. Модуль и переиспользуемость

### Код модуля `modules/lxd_instance/main.tf`

Модуль принимает параметры: `name`, `cpu`, `memory`, `disk_size`. Создаёт ресурс `lxd_instance` с заданными параметрами.

### Вызов модуля в `environments/dev/main.tf`

Модуль вызван дважды:
- **web_server**: 2 CPU, 2GiB RAM, 15GiB диск
- **db_server**: 4 CPU, 4GiB RAM, 30GiB диск

## Часть B. Управление состоянием

Использованные команды:
- `terraform init` — инициализация
- `terraform plan` — план изменений
- `terraform apply` — применение
- `terraform state list` — список ресурсов
- `terraform state show` — детали ресурса

## Часть C. Настройка через Ansible

Плейбук `configure.yml` выполняет:
1. Установка Nginx
2. Развёртывание index.html
3. Запуск сервиса Nginx

## Часть D. Единый конвейер

Скрипт `deploy.sh` автоматизирует:
1. `terraform init` + `terraform apply`
2. Ожидание готовности SSH
3. Запуск `ansible-playbook`

## Вопросы и ответы

### 1. Разница между локальным модулем и провайдером

**Модуль** — переиспользуемый блок кода, описывающий ресурсы. Создаётся пользователем.

**Провайдер** — плагин для взаимодействия с API (LXD, AWS и т.д.). Обеспечивает "драйвер" для ресурсов.

### 2. Почему при переименовании модуля нужен `terraform state mv`?

Без `state mv` Terraform удалит старый ресурс и создаст новый. `state mv` переносит запись в state без изменения инфраструктуры.

### 3. Чем `terraform apply -replace` лучше ручного удаления?

`-replace` делает атомарное пересоздание: удаляет старый ресурс и создаёт новый по коду, обновляя state. Ручное удаление оставляет "осиротевшую" запись.

### 4. Как SSH-ключ попадает в контейнер?

1. Terraform генерирует ключ через `tls_private_key`
2. Публичный ключ передаётся в модуль
3. Cloud-init добавляет ключ в `/home/ubuntu/.ssh/authorized_keys`

### 5. Опасность хранения приватного ключа в state

State-файл содержит секреты в открытом виде. При попадании в Git — компрометация всех серверов.

**Решение:** remote backend с шифрованием, HashiCorp Vault, `.gitignore` для `.tfstate`.

## Скриншоты

<img width="1280" height="800" alt="image" src="https://github.com/user-attachments/assets/c39fdbd6-da0e-46f0-8e51-696db6fc24ef" />



<img width="1280" height="800" alt="image" src="https://github.com/user-attachments/assets/7e0f849f-589d-4fad-a5e8-b91f470b8a19" />


