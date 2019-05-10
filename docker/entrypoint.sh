#!/bin/sh

cd /moebooru
cp -aR config_tmpl -T config

tables="$(psql "$MB_DATABASE_URL" -Aqtc "select count(*) from information_schema.tables where table_schema = 'public';")"


if [ "$tables" -eq 0 ]; then
    bundle exec rake db:reset || true
fi

bundle exec rake db:migrate
bundle exec unicorn
