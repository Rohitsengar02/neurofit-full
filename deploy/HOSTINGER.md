# NeuroFit API on Hostinger (api.bitechez.com)

Needs a Hostinger **VPS** (KVM plan, Ubuntu 22.04/24.04). Shared or "Node.js web app" hosting can't run
Postgres, the cache or live websockets, so it won't work there. The VPS that runs BiteChez is fine: NeuroFit
runs next to it and shares its HTTPS (Caddy).

## 1. DNS (where bitechez.com is managed, e.g. Hostinger hPanel > Domains > DNS)
Add an **A record**: name `api`, points to the VPS IP, TTL 300.

## 2. On the VPS (SSH as root)
```bash
git clone https://github.com/Rohitsengar02/neurofit-full.git
cd neurofit-full
sudo bash deploy/install.sh
```
It installs Docker if needed, asks for the admin login, the R2 keys and the LiveKit keys once, and saves them in
`deploy/.env` (only on the server). Then it starts the API, Postgres 16 and the Valkey cache, and adds
`api.bitechez.com` to the BiteChez Caddy so HTTPS works automatically.

**R2:** copy these lines from the BiteChez server's `.env` (same names work here):
`R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT`, `R2_BUCKET_NAME`, `R2_PUBLIC_DOMAIN`.
NeuroFit files go under their own folders (`users/...`, `admin/...`) in the same bucket.

**LiveKit:** cloud.livekit.io > project > Settings > Keys: `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`.

Check: open https://api.bitechez.com/api/health

## Updating later
```bash
cd neurofit-full && git pull && cd deploy && docker compose up -d --build
```
Change a key: edit `deploy/.env`, then `docker compose up -d`.

## Moving the data from Render (optional)
```bash
pg_dump "<Render external DATABASE_URL>" --clean --if-exists --no-owner --no-acl > neurofit.sql
docker compose exec -T neurofit-db psql -U neurofit -d neurofit < neurofit.sql
```
Run this right after the first start, before anyone signs up on the new server.

## Backups (daily, keeps 7)
```bash
(crontab -l; echo '0 3 * * * cd /root/neurofit-full/deploy && docker compose exec -T neurofit-db pg_dump -U neurofit neurofit | gzip > /root/neurofit-$(date +\%a).sql.gz') | crontab -
```
