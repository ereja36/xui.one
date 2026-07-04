#!/bin/bash
set -euo pipefail

echo "[paths] Configuring path-based routing (no extra ports)..."

DOMAIN="${DOMAIN:-}"
NGINX_CONF="/home/xui/bin/nginx/conf/nginx.conf"
NGINX_FRONT="/etc/nginx/sites-enabled/xui-unified.conf"
MARKER="/home/xui/config/docker-paths.configured"

# --- Update MySQL: all public URLs use port 80/443 (paths only) ---
if pgrep -x mysqld >/dev/null 2>&1; then
    echo "[paths] Updating database port settings..."

    mysql -u root xui 2>/dev/null <<'SQL' || true
UPDATE streaming_servers SET
    http_broadcast_port = 80,
    https_broadcast_port = 443,
    http_port = 80,
    https_port = 443
WHERE 1=1;

UPDATE servers SET
    http_broadcast_port = 80,
    https_broadcast_port = 443,
    http_port = 80,
    https_port = 443
WHERE 1=1;
SQL

    if [ -n "$DOMAIN" ]; then
        mysql -u root xui 2>/dev/null <<SQL || true
UPDATE streaming_servers SET
    domain_name = '${DOMAIN}',
    site_url = 'http://${DOMAIN}'
WHERE 1=1;
SQL
        echo "[paths] Domain set to: $DOMAIN"
    fi

    # Regenerate nginx ports from database
    if [ -x /home/xui/tools ]; then
        /home/xui/tools ports 2>/dev/null || true
        echo "[paths] Regenerated nginx ports from database"
    fi
fi

# --- Install front nginx reverse proxy on port 80/443 ---
if [ -f /home/xui/status ]; then
    if ! command -v nginx >/dev/null 2>&1; then
        apt-get update -qq && apt-get install -y -qq nginx >/dev/null 2>&1 || true
    fi

    if command -v nginx >/dev/null 2>&1; then
        mkdir -p /etc/nginx/sites-enabled /etc/nginx/sites-available

        cat > /etc/nginx/sites-available/xui-unified.conf <<'NGINX'
upstream xui_stream  { server 127.0.0.1:8000; keepalive 32; }
upstream xui_api     { server 127.0.0.1:25461; keepalive 16; }
upstream xui_admin   { server 127.0.0.1:8080; keepalive 16; }

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    client_max_body_size 0;
    proxy_buffering off;
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;

    # IPTV Live / VOD streaming (path-based)
    location ~ ^/(live|movie|series|streaming|hls|timeshift)/ {
        proxy_pass http://xui_stream;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
    }

    location ~ ^/(playlist|vod|static)/ {
        proxy_pass http://xui_stream;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # API (path-based, no :25461 in URL)
    location ~ ^/(player_api|panel_api|api|get|xmltv|epg|portal)\.php$ {
        proxy_pass http://xui_api;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Admin panel + access codes
    location / {
        proxy_pass http://xui_admin;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINX

        rm -f /etc/nginx/sites-enabled/default
        ln -sf /etc/nginx/sites-available/xui-unified.conf /etc/nginx/sites-enabled/xui-unified.conf

        # Stop XUI nginx from binding port 80 (front nginx takes over)
        if [ -f "$NGINX_CONF" ]; then
            sed -i 's/listen 80;/listen 127.0.0.1:8880;/g' "$NGINX_CONF" 2>/dev/null || true
            sed -i 's/listen \[::\]:80;/listen [::1]:8880;/g' "$NGINX_CONF" 2>/dev/null || true
        fi

        nginx -t 2>/dev/null && nginx -s reload 2>/dev/null || nginx 2>/dev/null || true
        echo "[paths] Front nginx proxy active on port 80"
    fi
fi

touch "$MARKER"
echo "[paths] Path-based routing configured."
