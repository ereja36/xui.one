#!/bin/bash
set -euo pipefail

echo "[configure] Applying network bindings..."

PHP_ETC="/home/xui/bin/php/etc"
if [ -d "$PHP_ETC" ]; then
    for conf in 1.conf 2.conf 3.conf 4.conf; do
        if [ -f "$PHP_ETC/$conf" ]; then
            sed -i 's/127\.0\.0\.1/0.0.0.0/g' "$PHP_ETC/$conf"
            sed -i 's/localhost/0.0.0.0/g' "$PHP_ETC/$conf"
            echo "[configure] Updated $PHP_ETC/$conf"
        fi
    done
fi

if [ -f /home/xui/config/config.ini ]; then
    sed -i 's/hostname = "127.0.0.1"/hostname = "0.0.0.0"/g' /home/xui/config/config.ini
fi

if [ -f /home/xui/bin/redis/redis.conf ]; then
    sed -i 's/^bind .*/bind 127.0.0.1/g' /home/xui/bin/redis/redis.conf
fi

if [ -f /etc/mysql/my.cnf ]; then
    sed -i 's/bind-address.*/bind-address = 127.0.0.1/g' /etc/mysql/my.cnf
fi

# Path-based routing (no extra ports in URLs)
if [ -f /configure-paths.sh ]; then
    /configure-paths.sh
fi

echo "[configure] Network configuration complete."
