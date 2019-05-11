#!/bin/sh

cd /moebooru

echo "$1:$2" | /iqdb add /moebooru/public/data/iq.db

/iqdb listen 0.0.0.0:5566 -r public/data/iq.db &
