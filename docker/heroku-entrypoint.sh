#!/bin/bash
set -euo pipefail

PORT="${PORT:-8080}"

echo "[heroku] Starting XUI.one on port $PORT..."

# Open Heroku port immediately (required within 60 seconds)
socat TCP-LISTEN:"$PORT",fork,reuseaddr TCP:127.0.0.1:8080 &
SOCAT_PID=$!

start_mariadb() {
    if ! pgrep -x mysqld >/dev/null 2>&1; then
        echo "[heroku] Starting MariaDB..."
        mkdir -p /var/run/mysqld
        chown -R mysql:mysql /var/run/mysqld /var/lib/mysql 2>/dev/null || true
        mysqld_safe --datadir=/var/lib/mysql &
        sleep 5
    fi
}

start_mariadb
/configure.sh

echo "[heroku] Starting XUI.one services..."
/home/xui/service start || true

# If XUI listens on port 80 instead of 8080, update socat target
sleep 5
if ! curl -sf http://127.0.0.1:8080 >/dev/null 2>&1; then
    if curl -sf http://127.0.0.1:80 >/dev/null 2>&1; then
        kill "$SOCAT_PID" 2>/dev/null || true
        exec socat TCP-LISTEN:"$PORT",fork,reuseaddr TCP:127.0.0.1:80
    fi
fi

if [ -f /root/credentials.txt ]; then
    echo "=============================================="
    echo " XUI.one credentials:"
    cat /root/credentials.txt
    echo "=============================================="
fi

# Keep dyno alive
wait "$SOCAT_PID"
