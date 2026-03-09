#!/bin/bash
set -euo pipefail

cd /rails

bundle exec whenever --update-crontab pixelup_production --set "environment=${RAILS_ENV:-production}&path=/rails"

exec cron -f
