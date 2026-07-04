#!/bin/bash
set -euo pipefail

echo "[install] Starting XUI.one installation (this can take 10-15 minutes)..."

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq python3 python3-dev unzip wget >/dev/null

cd /root

if [ ! -f /root/XUI_1.5.12.zip ]; then
    echo "[install] Downloading XUI.one 1.5.12..."
    wget -q https://github.com/amidevous/xui.one/releases/download/test/XUI_1.5.12.zip -O XUI_1.5.12.zip
fi

if [ ! -f /root/xui.tar.gz ] && [ ! -f /root/xui_trial.tar.gz ]; then
    echo "[install] Extracting package..."
    unzip -o XUI_1.5.12.zip -d /root >/dev/null
fi

if [ ! -f /root/install.python3 ]; then
    wget -q https://raw.githubusercontent.com/amidevous/xui.one/master/install.python3 -O /root/install.python3
fi

chmod +x /root/install.python3

# Non-interactive install: auto-confirm overwrite if directory exists
export PYTHONUNBUFFERED=1
echo "Y" | python3 /root/install.python3 || {
    echo "[install] Installation script finished with warnings, checking status..."
}

if [ ! -f /home/xui/status ]; then
    echo "[install] ERROR: Installation failed - /home/xui/status not found."
    exit 1
fi

/configure.sh

echo "[install] Installation completed successfully."
