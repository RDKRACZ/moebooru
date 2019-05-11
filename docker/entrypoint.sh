#!/bin/sh

cd /moebooru

/iqdb-query &

/iqdb listen 0.0.0.0:5566 public/data/iq.db &

files="$(find config -mindepth 1 | wc -l)"

if [ "$files" -eq 0 ]; then
    cp -aR config_tmpl -T config
fi

cat >config/local_config.rb <<EOF
CONFIG["app_name"] = "iibooru"
CONFIG["server_host"] = "$MB_HOST_NAME"
CONFIG["url_base"] = "$MB_URL_BASE"
CONFIG["admin_contact"] = "$MB_ADMIN_CONTACT"
CONFIG["local_image_service"] = CONFIG["app_name"]
CONFIG["image_service_list"][CONFIG["local_image_service"]] = "http://127.0.0.1:8082/iqdb"
CONFIG['dupe_check_on_upload'] = true
EOF


tables="$(psql "$MB_DATABASE_URL" -Aqtc "select count(*) from information_schema.tables where table_schema = 'public';")"

if [ "$tables" -eq 0 ]; then
    bundle exec rake db:reset || true
fi

bundle exec rake db:migrate
bundle exec unicorn
