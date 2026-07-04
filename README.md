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
├── docker-compose.yml      # Compose me volume dhe porta
├── docker/
│   ├── entrypoint.sh       # Start / install automatik
│   ├── configure.sh        # Konfigurim IP 0.0.0.0
│   └── install-docker.sh   # Instalim XUI.one
└── install.sh              # Instalim VPS origjinal
```
