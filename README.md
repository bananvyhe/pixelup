# Pixelup

Rails 8 приложение с:

- входом через `jwt_sessions`
- frontend на `Vue 3 Composition API`
- ролями `admin`, `user`, `client`
- кабинетом клиента с балансом и расчётом оставшихся дней
- пополнением через YooMoney
- админкой со списком пользователей и редактированием прав
- почасовым списанием средств через `Sidekiq`
- расписанием периодических задач через `whenever`
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
8. Применить расписание cron через whenever:
   `./scripts/dev_apply_schedule.sh`
9. Запустить воркер:
   `bundle exec sidekiq -C config/sidekiq.yml`

Если меняли `config/schedule.rb`, credentials или Ruby/toolchain, заново примените cron:

```bash
./scripts/dev_apply_schedule.sh
```

Либо поднять dev-сервисы одной командой:

```bash
./scripts/dev_up.sh
```

## Переменные окружения

- `JWT_SIGNING_KEY` или `credentials.jwt.signing_key`
- `REDIS_URL` или `credentials.redis.url`
- `APP_BASE_URL` для `successURL` YooMoney
- `YOOMONEY_RECEIVER` или `credentials.yoomoney.receiver`
- `YOOMONEY_NOTIFICATION_SECRET` или `credentials.yoomoney.notification_secret`
- `SIDEKIQ_WEB_USERNAME` или `credentials.sidekiq.web_username`
- `SIDEKIQ_WEB_PASSWORD` или `credentials.sidekiq.web_password`
- `PGHOST` / `PGPORT` / `PGUSER` / `PGPASSWORD` / `PGDATABASE` или `credentials.postgres.*`

Секреты лучше хранить в `Rails credentials`:

```bash
EDITOR=nano bin/rails credentials:edit
```

Пример структуры:

```yml
jwt:
  signing_key: "..."

postgres:
  host: "127.0.0.1"
  port: 5432
  username: "rufus"
  password: ""
  development_database: "pixelup_development"
  test_database: "pixelup_test"
  production_database: "pixelup_production"

redis:
  host: "127.0.0.1"
  port: 6379
  db: 0
  password: ""
  url: ""

yoomoney:
  receiver: "..."
  notification_secret: "..."
sidekiq:
  web_username: "admin"
  web_password: "CHANGE_ME_SIDEKIQ_PASSWORD"
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
