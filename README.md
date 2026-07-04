# xui.one Auto Install Script

Skript automatizimi për instalimin e **XUI.one** me **streaming IPTV**, **path-based URLs** (pa porta në link) dhe **të dhëna persistente** pas restart.

## Instalim me Docker (rekomanduar)

### Kërkesat

- Docker Engine 24+
- Docker Compose v2
- Minimum 4GB RAM
- Minimum 20GB disk

### Hapat

```bash
git clone https://github.com/ereja36/xui.one
cd xui.one
cp .env.example .env
# Ndrysho DOMAIN=panel.example.com në .env
docker compose up -d --build
```

Instalimi i parë zgjat **10–15 minuta**:

```bash
docker compose logs -f
```

### Kredencialet (ruhen pas restart)

```bash
docker exec xuione cat /home/xui/config/credentials.txt
```

Të dhënat ruhen në volume Docker — **nuk humbasin pas restart**:

| Volume | Përmbajtja |
|--------|------------|
| `xui_home` | Paneli, streams, konfigurime |
| `xui_mysql` | Database |

### URL format (path-based, pa port)

| Funksioni | URL |
|-----------|-----|
| Admin panel | `http://DOMAIN/KODI_AKSESIT` |
| Live stream | `http://DOMAIN/live/USER/PASS/STREAM_ID.ts` |
| Movie/VOD | `http://DOMAIN/movie/USER/PASS/MOVIE_ID.mkv` |
| API | `http://DOMAIN/player_api.php?username=USER&password=PASS` |
| EPG | `http://DOMAIN/xmltv.php?username=USER&password=PASS` |

Vetëm portet **80** dhe **443** janë të hapura. Gjithçka tjetër funksionon me **path**.

### Komanda të dobishme

```bash
docker compose restart              # rinis (të dhënat mbeten)
docker compose down                 # ndalon (të dhënat mbeten)
docker compose down -v              # fshin GJITHÇKA (ri-instalim)
docker exec xuione /home/xui/service restart
```

### Backup të dhënash

```bash
docker run --rm -v xui_home:/data -v $(pwd):/backup ubuntu tar czf /backup/xui-backup.tar.gz -C /data .
docker run --rm -v xui_mysql:/data -v $(pwd):/backup ubuntu tar czf /backup/mysql-backup.tar.gz -C /data .
```

---

## Instalim direkt në VPS (Ubuntu)

```bash
apt-get install git -y
git clone https://github.com/ereja36/xui.one
cd xui.one
chmod +x install.sh
./install.sh
```

### Konfigurim manual pas instalimit (VPS)

```bash
# 1. IP binding
sed -i 's/127.0.0.1/0.0.0.0/g' /home/xui/bin/php/etc/{1,2,3,4}.conf

# 2. libssl1.1 (Ubuntu 24.04)
wget https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb
sudo dpkg -i ./libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb

# 3. Rinis
sudo systemctl restart xuione.service
```

---

## Heroku

Heroku **nuk mbështet streaming IPTV** (një port, filesystem efemer). Përdor Docker në VPS për streaming të plotë.

---

## Struktura e projektit

```
xui.one/
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── docker/
│   ├── entrypoint.sh
│   ├── configure.sh
│   ├── configure-paths.sh    # Path routing pa porta
│   ├── persist-data.sh       # Ruajtje e të dhënave
│   ├── install-docker.sh
│   └── nginx-unified.conf
└── install.sh
```
