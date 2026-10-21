Отчёт B2: block/rescue/always


Вопросы и ответы
1. Чем block/rescue/always отличаются от try/catch/finally в Python?

Это прямые аналоги. block — как try: основной блок действий. rescue — как catch: сюда попадаем при ошибке. always — как finally: выполняется в любом случае, нужен для очистки и финальных действий.

2. Когда срабатывает always — даже если упал rescue?

Всегда, и всегда последним. Даже если ошибка возникла в block и обработка в rescue тоже завершилась ошибкой, always всё равно выполнится — например, чтобы отправить финальный лог или убрать временные файлы.

3. Что делает модуль fail и зачем он в rescue?

fail принудительно завершает задачу с заданным сообщением. В rescue он нужен, чтобы после успешного отката плейбук всё равно закончился со статусом FAILED: инцидент произошёл, и администратор должен об этом узнать, даже если инфраструктура уже приведена в порядок.

4. Как добавить уведомление в Telegram при ошибке?

В секцию rescue добавляется задача с модулем uri:

yaml
- name: Notify Telegram
  uri:
    url: "https://api.telegram.org/bot<TOKEN>/sendMessage"
    method: POST
    body_format: json
    body: '{"chat_id": "12345", "text": "Update failed on {{ ansible_hostname }}"}'
5. Почему важно делать бэкапы перед изменениями?

Бэкап — единственная реальная гарантия отката. Он нужен при фатальной ошибке, при несовместимости нового конфига с текущей системой и при сбое оборудования в момент записи. Без копии откатываться просто не к чему.
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

