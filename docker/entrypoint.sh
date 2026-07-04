#!/bin/bash
set -euo pipefail

start_mariadb() {
    if ! pgrep -x mysqld >/dev/null 2>&1; then
        echo "[entrypoint] Starting MariaDB..."
        mkdir -p /var/run/mysqld
        chown -R mysql:mysql /var/run/mysqld /var/lib/mysql 2>/dev/null || true
        service mariadb start || mysqld_safe --datadir=/var/lib/mysql &
        sleep 5
    fi
}

start_nginx() {
    if command -v nginx >/dev/null 2>&1; then
        nginx -t 2>/dev/null && nginx -s reload 2>/dev/null || nginx 2>/dev/null || true
    fi
}

start_xui() {
    echo "[entrypoint] Starting XUI.one services..."
    /configure.sh
    /home/xui/service start || true
    sleep 3
    start_nginx
}

show_credentials() {
    CRED="/home/xui/config/credentials.txt"
    if [ -f "$CRED" ]; then
        echo ""
        echo "=============================================="
        echo " XUI.one is running (path-based, port 80)"
        echo " Credentials (persistent): $CRED"
        cat "$CRED"
        echo ""
        echo " Streaming URL format:"
        echo "   http://DOMAIN/live/USER/PASS/STREAM_ID.ts"
        echo "   http://DOMAIN/player_api.php?username=USER&password=PASS"
        echo "=============================================="
        echo ""
    elif [ -f /root/credentials.txt ]; then
        /persist-data.sh
        show_credentials
    fi
}

if [ ! -f /home/xui/status ]; then
    echo "[entrypoint] Fresh install detected."
    /install-docker.sh
    /persist-data.sh
else
    echo "[entrypoint] Existing installation found (data persisted)."
fi

start_mariadb
start_xui
show_credentials

# Keep container alive, restart services if they die
while true; do
    if ! pgrep -x mysqld >/dev/null 2>&1; then
        echo "[entrypoint] MariaDB stopped, restarting..."
        start_mariadb
    fi
    if ! pgrep -x nginx >/dev/null 2>&1 && command -v nginx >/dev/null 2>&1; then
        echo "[entrypoint] Nginx stopped, restarting..."
        start_nginx
    fi
    sleep 30
done
