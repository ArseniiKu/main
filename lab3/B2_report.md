Отчёт B2: block/rescue/always

Выполнил: Кучин Арсений
Дата: 28 сентября 2026
Вопросы и ответы
1. Объясните разницу между block/rescue/always и try/catch/finally в Python.
Это прямые аналоги:
block = try (основной код)
rescue = catch (обработка исключения)
always = finally (выполняется в любом случае для очистки)
2. Когда срабатывает always — даже если rescue тоже упал?
Всегда, в самом конце. Даже если задача в block упала, и задача в rescue тоже упала, always всё равно выполнится (например, для отправки финального лога или очистки временных файлов).
3. Что делает модуль fail и зачем он нужен в rescue?
Он принудительно "валит" задачу с заданным сообщением. Это нужно, чтобы после успешного отката (rescue) плейбук всё равно завершился с ошибкой (FAILED), привлекая внимание администратора к тому, что инцидент произошёл.
4. Как бы вы добавили отправку уведомления в Telegram при ошибке?
В секцию rescue добавить задачу с модулем uri:

- name: Notify Telegram
  uri:
    url: "https://api.telegram.org/bot<TOKEN>/sendMessage"
    method: POST
    body_format: json
    body: '{"chat_id": "12345", "text": "Update failed on {{ ansible_hostname }}"}'

5. Почему важно сохранять бэкапы перед изменениями?
Это единственная гарантия возможности отката (rollback) при:
Фатальной ошибке
Синтаксической несовместимости нового конфига
Сбое оборудования во время записи
Результаты выполнения
Нормальный запуск:

$ ansible-playbook playbooks/safe-update.yml

PLAY RECAP *********************************************************************
node1    : ok=9  changed=4  unreachable=0  failed=0
node2    : ok=9  changed=4  unreachable=0  failed=0

С симуляцией ошибки:

$ ansible-playbook playbooks/safe-update.yml -e "simulate_failure=true"

PLAY RECAP *********************************************************************
node1    : ok=9  changed=4  unreachable=0  failed=1  rescued=1
node2    : ok=9  changed=4  unreachable=0  failed=1  rescued=1

