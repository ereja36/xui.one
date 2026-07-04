# xui.one Auto Install Script

Skript automatizimi për instalimin e **XUI.one** në Ubuntu VPS ose në **Docker**.

## Instalim me Docker (rekomanduar)

### Kërkesat

- Docker Engine 24+
- Docker Compose v2
- Minimum 4GB RAM (instalimi konsumon shumë memorie)
- Minimum 20GB disk

### Hapat

```bash
git clone https://github.com/ereja36/xui.one
cd xui.one
docker compose up -d --build
```

Instalimi i parë zgjat **10–15 minuta**. Shiko progresin:

```bash
docker compose logs -f
```

Kur të përfundojë, kredencialet shfaqen në log:

```bash
docker compose logs | grep -A5 "XUI.one is running"
```

Ose lexoji direkt nga kontejneri:

```bash
docker exec xuione cat /root/credentials.txt
```

### Hap panelin

Hap në shfletues URL-në që del në `credentials.txt`, zakonisht:

```
http://IP_E_SERVERIT/KODI_I_AKSESIT
```

Portet e hapura:

| Port | Përdorimi |
|------|-----------|
| 80 | HTTP |
| 443 | HTTPS |
| 8080 | Admin panel |
| 2086 | Client port |
| 8000 | Streaming |
| 25461 | API |

### Komanda të dobishme

```bash
# Rinis shërbimin
docker compose restart

# Ndalo
docker compose down

# Ri-instalim i pastër (fshin të dhënat!)
docker compose down -v
docker compose up -d --build

# Hyr në kontejner
docker exec -it xuione bash

# Rinis XUI brenda kontejnerit
docker exec xuione /home/xui/service restart
```

### Çfarë bën automatikisht

Docker setup-i aplikon konfigurimin që duhet bërë manualisht në VPS:

1. Instalon `libssl1.1` (e nevojshme për PHP në Ubuntu 24.04)
2. Ndryshon `127.0.0.1` → `0.0.0.0` në `/home/xui/bin/php/etc/1.conf` – `4.conf`
3. Konfiguron MySQL, Redis dhe config.ini për akses nga jashtë
4. Ruan të dhënat në volume persistent (`xui_home`, `xui_mysql`)

---

## Instalim në Heroku (nga GitHub Web)

> **Kujdes:** Heroku mbështet vetëm **panelin admin** (web UI). Streaming IPTV **nuk funksionon** në Heroku sepse kërkon shumë porta dhe filesystem të qëndrueshëm. Për streaming, përdor VPS ose Docker.

### Hapat në Heroku Dashboard

1. Hyr në [dashboard.heroku.com](https://dashboard.heroku.com)
2. Kliko **New** → **Create new app**
3. Emërto app-in (p.sh. `xui-panel-ime`)
4. Te **Deployment method**, zgjidh **GitHub**
5. Lidh repo-n `ereja36/xui.one`
6. Te **Settings** → **Config Vars**: shto `TZ=UTC` (opsionale)
7. Te **Settings** → **Stack**: zgjidh **Container** (heroku-24)
8. Aktivizo **Automatic deploys** nga branch `main` (ose `cursor/docker-xui-setup-554e`)
9. Kliko **Deploy Branch**

### Ose me Heroku CLI

```bash
heroku login
heroku create xui-panel-ime --stack container
heroku stack:set container
heroku git:remote -a xui-panel-ime
git push heroku cursor/docker-xui-setup-554e:main
```

### Pas deploy-it

```bash
heroku logs --tail -a xui-panel-ime
heroku open -a xui-panel-ime
```

Kredencialet shfaqen në logs. Kërko rreshtin `Continue Setup:`.

### Kufizimet në Heroku

| Funksion | Heroku | VPS/Docker |
|----------|--------|------------|
| Admin panel (web) | Po (me kufizime) | Po |
| Streaming IPTV | **Jo** | Po |
| Porta 8000, 2086, 25461 | **Jo** | Po |
| Të dhëna pas restart | **Humben** | Ruhen (volume) |
| Redis Premium add-on | Nuk lidhet automatikisht | Redis lokal |

**Rekomandim:** Përdor dyno **Standard-2X** (1GB RAM) ose më të madh. Build zgjat 10–15 minuta.

---

## Instalim direkt në VPS (Ubuntu)

> **Vetëm në Ubuntu të pastër** (18, 20, 22, 24)

```bash
apt-get install git -y
git clone https://github.com/ereja36/xui.one
cd xui.one
chmod +x install.sh
./install.sh
```

### Konfigurim manual pas instalimit (VPS)

```bash
# 1. Ndrysho IP në konfigurime PHP
sed -i 's/127.0.0.1/0.0.0.0/g' /home/xui/bin/php/etc/{1,2,3,4}.conf

# 2. Instalo libssl1.1 (Ubuntu 24.04)
wget https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb
sudo dpkg -i ./libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb

# 3. Rinis shërbimin
sudo systemctl restart xuione.service
# ose: /home/xui/service restart
```

---

## Struktura e projektit

```
xui.one/
├── Dockerfile              # Imazh Ubuntu 24.04 + dependencies
├── Dockerfile.heroku       # Imazh për Heroku (install gjatë build)
├── heroku.yml              # Konfigurim deploy nga GitHub
├── app.json                # Template Heroku app
├── docker-compose.yml      # Compose me volume dhe porta
├── docker/
│   ├── entrypoint.sh       # Start / install automatik
│   ├── heroku-entrypoint.sh # Start + $PORT për Heroku
│   ├── configure.sh        # Konfigurim IP 0.0.0.0
│   ├── install-docker.sh   # Instalim XUI.one
│   └── install-heroku.sh   # Instalim gjatë build për Heroku
└── install.sh              # Instalim VPS origjinal
```
