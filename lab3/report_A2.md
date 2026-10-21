# Отчёт по заданию A2: Vault ID — разные пароли для разных окружений


1. Что такое vault_id и зачем он нужен?

vault_id позволяет использовать разные пароли для разных зашифрованных файлов. Формат — label@password_source, где label — метка (например, dev, prod, staging), а password_source — файл с паролем либо prompt для интерактивного ввода.

Пример:

bash
ansible-vault encrypt secrets_dev.yml --vault-id dev@.vault_pass_dev
ansible-vault encrypt secrets_prod.yml --vault-id prod@.vault_pass_prod
При запуске можно указать несколько идентификаторов сразу:

bash
ansible-playbook deploy.yml --vault-id dev@.vault_pass_dev --vault-id prod@.vault_pass_prod
2. Почему нельзя использовать один vault-пароль для всех окружений?

Единый пароль создаёт сразу несколько проблем:

Компрометация одного = компрометация всех. Пароль от dev открывает и prod-секреты.

Нарушается разделение обязанностей. Разработчики не должны иметь доступа к production-паролям.

Ротация усложняется. При смене пароля приходится синхронно обновлять все окружения.

Не соответствуют требованиям. Стандарты (SOC2, ISO27001) требуют разграничения доступа по окружениям.

Best practice — минимум три разных пароля: для dev, staging и production.

3. Как передать несколько vault-паролей в GitLab CI?

yaml
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
    DEV_VAULT_PASSWORD: $VAULT_DEV_PASS
    PROD_VAULT_PASSWORD: $VAULT_PROD_PASS
  only:
    - main
Здесь $VAULT_DEV_PASS и $VAULT_PROD_PASS — защищённые переменные в настройках GitLab CI/CD.

4. Что произойдёт при неправильном vault-пароле?

Ansible завершится с ошибкой:

text
ERROR: Decryption failed on secrets_dev.yml
При этом конкретный файл в сообщении не уточняется — это сделано намеренно, в целях безопасности. Проверить стоит три вещи:

правильность пароля;

соответствие vault-id (не перепутаны ли dev и prod);

права на файл с паролем (chmod 600).

5. Почему .vault_pass_* добавлены в .gitignore?

Потому что попадание vault-пароля в Git обесценивает всё шифрование:

зашифрованные секреты расшифровываются за считаные секунды;

требуется срочная смена всех паролей и повторное шифрование файлов;

возможны утечка данных и финансовые потери.

Правило: .vault_pass_* должны быть в .gitignore всегда. Альтернатива — передавать пароль через переменные окружения, а не через файлы.

Пример .gitignore:

text
.vault_pass_*
*.vault_pass
