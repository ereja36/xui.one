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

start_xui() {
    echo "[entrypoint] Starting XUI.one services..."
    /configure.sh
    /home/xui/service start || true
}

if [ ! -f /home/xui/status ]; then
    echo "[entrypoint] Fresh install detected."
    /install-docker.sh
else
    echo "[entrypoint] Existing installation found."
fi

start_mariadb
start_xui

if [ -f /root/credentials.txt ]; then
    echo ""
    echo "=============================================="
    echo " XUI.one is running"
    echo " Credentials: /root/credentials.txt"
    cat /root/credentials.txt
    echo "=============================================="
    echo ""
fi

# Keep container alive and restart services if they die
while true; do
    if ! pgrep -x mysqld >/dev/null 2>&1; then
        echo "[entrypoint] MariaDB stopped, restarting..."
        start_mariadb
    fi
    sleep 30
done
