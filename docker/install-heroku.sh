#!/bin/bash
set -euo pipefail

echo "[heroku-install] Starting XUI.one build-time installation..."

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq python3 python3-dev unzip wget mariadb-server >/dev/null

# Start MariaDB temporarily for database setup during build
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql 2>/dev/null || true
mysqld_safe --datadir=/var/lib/mysql &
sleep 8

cd /root

echo "[heroku-install] Downloading XUI.one 1.5.12..."
wget -q https://github.com/amidevous/xui.one/releases/download/test/XUI_1.5.12.zip -O XUI_1.5.12.zip
unzip -o XUI_1.5.12.zip -d /root >/dev/null

wget -q https://raw.githubusercontent.com/amidevous/xui.one/master/install.python3 -O /root/install.python3
chmod +x /root/install.python3

# Speed up build: reduce long sleeps and skip systemd (not available in build)
sed -i 's/time\.sleep(60)/time.sleep(3)/g' /root/install.python3
sed -i 's/time\.sleep(10)/time.sleep(2)/g' /root/install.python3
sed -i 's/systemctl start xuione/\/home\/xui\/service start/g' /root/install.python3
sed -i 's/systemctl stop xuione/\/home\/xui\/service stop/g' /root/install.python3
sed -i 's/systemctl daemon-reload/true/g' /root/install.python3
sed -i 's/systemctl enable xuione/true/g' /root/install.python3

export PYTHONUNBUFFERED=1
echo "Y" | python3 /root/install.python3 || {
    echo "[heroku-install] Install script finished with warnings, checking status..."
}

if [ ! -f /home/xui/status ]; then
    echo "[heroku-install] ERROR: Installation failed."
    exit 1
fi

/configure.sh

# Stop MariaDB after build
mysqladmin shutdown 2>/dev/null || pkill mysqld || true
sleep 2

echo "[heroku-install] Build-time installation completed."
