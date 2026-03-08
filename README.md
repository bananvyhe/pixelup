# Pixelup

Rails 8 приложение с:

- входом через `jwt_sessions`
- frontend на `Vue 3 Composition API`
- ролями `admin`, `user`, `client`
- кабинетом клиента с балансом и расчётом оставшихся дней
- пополнением через YooMoney
- админкой со списком пользователей и редактированием прав
- почасовым списанием средств через `Sidekiq`
- импортом пользователей из CSV

## Запуск

1. Выполнить `bundle install`.
2. Выполнить `cd frontend && npm install`.
3. Поднять локальные PostgreSQL и Redis:
   `./scripts/dev_services_up.sh`
4. Выполнить `bundle exec rails db:prepare`.
5. При необходимости создать админа:
   `ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=secret bundle exec rails db:seed`
6. Запустить Rails API:
   `bundle exec rails server -b 127.0.0.1 -p 3000`
7. Запустить Vue frontend:
   `cd frontend && npm run dev -- --host 127.0.0.1`
8. Запустить воркер:
   `bundle exec sidekiq -C config/sidekiq.yml`

Либо поднять dev-сервисы одной командой:

```bash
./scripts/dev_up.sh
```

## Переменные окружения

- `JWT_SIGNING_KEY` или `credentials.jwt.signing_key`
- `REDIS_URL`
- `APP_BASE_URL` для `successURL` YooMoney
- `YOOMONEY_RECEIVER` или `credentials.yoomoney.receiver`
- `YOOMONEY_NOTIFICATION_SECRET` или `credentials.yoomoney.notification_secret`

Секреты лучше хранить в `Rails credentials`:

```bash
EDITOR=nano bin/rails credentials:edit
```

Пример структуры:

```yml
jwt:
  signing_key: "..."
yoomoney:
  receiver: "..."
  notification_secret: "..."
app:
  base_url: "http://127.0.0.1:3000"
```

`config/master.key` нельзя коммитить в репозиторий.

## Импорт пользователей

CSV запускается так:

```bash
bundle exec rake users:import CSV=tmp/users.csv
```

Импорт из старой базы Pixeltech:

```bash
OLD_DATABASE_URL=postgres://USER:PASS@HOST:5432/DBNAME bundle exec rake users:import_pixeltech
```

Если база доступна только на VPS, можно использовать SSH-туннель:

```bash
ssh -L 55432:127.0.0.1:5432 USER@YOUR_VPS
OLD_DATABASE_URL=postgres://USER:PASS@127.0.0.1:55432/DBNAME bundle exec rake users:import_pixeltech
```

Поддерживаемые поля:

- `email`
- `password`
- `role`
- `hourly_rate_cents`
- `balance_cents`
- `active`
- `external_id`
- `source`
