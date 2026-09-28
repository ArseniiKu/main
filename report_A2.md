# Отчёт по заданию A2: Vault ID — разные пароли для разных окружений

### 1. Что такое `vault_id` и зачем он нужен?
**Vault ID** — это механизм Ansible, позволяющий использовать **разные пароли** для шифрования разных файлов. Формат: `label@password_source`, где:
- `label` — метка окружения (dev, prod, staging)
- `password_source` — файл с паролем или `prompt` для интерактивного ввода

Пример:
```bash
ansible-vault encrypt secrets_dev.yml --vault-id dev@.vault_pass_dev
ansible-vault encrypt secrets_prod.yml --vault-id prod@.vault_pass_prod
При запуске:
ansible-playbook deploy.yml --vault-id dev@.vault_pass_dev --vault-id prod@.vault_pass_prod
2. Почему нельзя использовать один vault-пароль для всех окружений?
Проблемы единого пароля:

    Компрометация одного = компрометация всех: Если злоумышленник получит dev-пароль, он получит доступ к prod-секретам
    Нарушение принципа разделения обязанностей: Разработчики не должны иметь доступ к prod-паролям
    Сложность ротации: При смене пароля нужно обновлять все окружения одновременно
    Несоответствие compliance: Стандарты (SOC2, ISO27001) требуют разделения доступа по окружениям

Best practice: Минимум 3 разных пароля: dev, staging, production.
3. Как бы вы передали несколько vault-паролей в GitLab CI?
# .gitlab-ci.yml
deploy_dev:
  stage: deploy
  script:
    - echo "$DEV_VAULT_PASSWORD" > .vault_pass_dev
    - echo "$PROD_VAULT_PASSWORD" > .vault_pass_prod
    - ansible-playbook deploy.yml 
      --vault-id dev@.vault_pass_dev 
      --vault-id prod@.vault_pass_prod
  variables:
    DEV_VAULT_PASSWORD: $VAULT_DEV_PASS  # Из настроек CI
    PROD_VAULT_PASSWORD: $VAULT_PROD_PASS
  only:
    - main
Где $VAULT_DEV_PASS и $VAULT_PROD_PASS — защищённые переменные в GitLab CI/CD Settings.
4. Что произойдёт, если передать неправильный vault-пароль?
Ansible выдаст ошибку:
ERROR: Decryption failed on secrets_dev.yml
Важно: Ansible не уточнит, какой именно файл не расшифровался — это мера безопасности. Нужно проверить:

    Правильность пароля
    Соответствие vault-id (dev vs prod)
    Права доступа к файлу пароля (chmod 600)

5. Почему файлы .vault_pass_* добавлены в .gitignore?
Критическая причина: Если vault-пароль попадёт в Git:

    Все зашифрованные секреты станут бесполезными (злоумышленник расшифрует их за секунды)
    Потребуется紧急 смена всех паролей и перешифрование файлов
    Возможна утечка данных и финансовые потери

Правило: .vault_pass_* должны быть в .gitignore ВСЕГДА. Альтернатива — использовать переменные окружения вместо файлов.
Пример .gitignore:
.vault_pass_*
*.vault_pass
