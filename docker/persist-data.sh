#!/bin/bash
set -euo pipefail

# Persist credentials and config to /home/xui volume (survives restart)
PERSIST_DIR="/home/xui/config"
CRED_SRC="/root/credentials.txt"
CRED_DST="$PERSIST_DIR/credentials.txt"

mkdir -p "$PERSIST_DIR"

if [ -f "$CRED_SRC" ]; then
    cp -f "$CRED_SRC" "$CRED_DST"
    echo "[persist] Credentials saved to $CRED_DST"
fi

# Save install info
cat > "$PERSIST_DIR/docker-info.txt" <<EOF
installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
domain=${DOMAIN:-not-set}
routing=path-based
ports=80,443
EOF

echo "[persist] Data persisted to volume /home/xui"
