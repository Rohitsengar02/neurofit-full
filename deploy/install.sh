#!/usr/bin/env bash
# One-time setup of the NeuroFit API on a Hostinger VPS (Ubuntu), at https://api.bitechez.com
#   git clone https://github.com/Rohitsengar02/neurofit-full.git && cd neurofit-full
#   sudo bash deploy/install.sh
# Safe to run again: it keeps the existing deploy/.env and only rebuilds and restarts.
set -euo pipefail
cd "$(dirname "$0")"

API_DOMAIN="${API_DOMAIN:-api.bitechez.com}"
BITECHEZ_DIR="${BITECHEZ_DIR:-}"

# 1. Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "==> Installing Docker"
  curl -fsSL https://get.docker.com | sh
fi

# 2. Secrets file (asked once, kept in deploy/.env, never committed)
rand() { head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c "${1:-40}"; }
ask() { local v; read -r -p "$1: " v; printf '%s' "$v"; }
if [ ! -f .env ]; then
  echo "==> Creating deploy/.env (press Enter to skip any key and add it later)"
  ADMIN_EMAIL=$(ask "Admin email for the NeuroFit admin panel")
  ADMIN_PASSWORD=$(ask "Admin password (leave empty to generate one)")
  [ -z "$ADMIN_PASSWORD" ] && ADMIN_PASSWORD="Nf-$(rand 14)"
  echo "    Paste the R2 lines from the BiteChez .env (same Cloudflare account and bucket):"
  R2_ACCOUNT_ID=$(ask "R2_ACCOUNT_ID")
  R2_ACCESS_KEY_ID=$(ask "R2_ACCESS_KEY_ID")
  R2_SECRET_ACCESS_KEY=$(ask "R2_SECRET_ACCESS_KEY")
  R2_ENDPOINT=$(ask "R2_ENDPOINT (optional)")
  R2_BUCKET_NAME=$(ask "R2_BUCKET_NAME")
  R2_PUBLIC_DOMAIN=$(ask "R2_PUBLIC_DOMAIN (e.g. https://pub-xxxx.r2.dev or https://cdn.bitechez.com)")
  echo "    LiveKit (cloud.livekit.io > your project > Settings > Keys):"
  LIVEKIT_URL=$(ask "LIVEKIT_URL (wss://xxxx.livekit.cloud)")
  LIVEKIT_API_KEY=$(ask "LIVEKIT_API_KEY")
  LIVEKIT_API_SECRET=$(ask "LIVEKIT_API_SECRET")
  umask 077
  cat > .env <<ENV
API_DOMAIN=$API_DOMAIN
POSTGRES_PASSWORD=$(rand 32)
VALKEY_PASSWORD=$(rand 32)
JWT_SECRET=$(rand 64)
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD
GOOGLE_WEB_CLIENT_ID=465865494955-7q16j5dqtsnt8rusbdicmsiftjo6mf0j.apps.googleusercontent.com
R2_ACCOUNT_ID=$R2_ACCOUNT_ID
R2_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY
R2_ENDPOINT=$R2_ENDPOINT
R2_BUCKET_NAME=$R2_BUCKET_NAME
R2_PUBLIC_DOMAIN=$R2_PUBLIC_DOMAIN
LIVEKIT_URL=$LIVEKIT_URL
LIVEKIT_API_KEY=$LIVEKIT_API_KEY
LIVEKIT_API_SECRET=$LIVEKIT_API_SECRET
CORS_ORIGINS=
ENV
  echo "    Saved. Admin login: $ADMIN_EMAIL / $ADMIN_PASSWORD"
fi

# 3. HTTPS: share the BiteChez Caddy when it runs on this server, else run our own.
CADDY_PROFILE=""
if docker network inspect bitechez_default >/dev/null 2>&1; then
  echo "==> BiteChez found on this server: its Caddy will serve $API_DOMAIN"
  sed -i '/^EDGE_NETWORK=/d' .env && echo "EDGE_NETWORK=bitechez_default" >> .env
  if [ -z "$BITECHEZ_DIR" ]; then
    BITECHEZ_DIR=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' \
      "$(docker ps -q --filter label=com.docker.compose.project=bitechez --filter label=com.docker.compose.service=caddy | head -1)" 2>/dev/null || true)
  fi
  CF="$BITECHEZ_DIR/deploy/Caddyfile"
  if [ -n "$BITECHEZ_DIR" ] && [ -f "$CF" ]; then
    if ! grep -q "^$API_DOMAIN" "$CF"; then
      # Must come before the catch-all "https://" block; a named site always wins over it in Caddy.
      sed "s/api.bitechez.com/$API_DOMAIN/" bitechez-caddy-block.txt >> "$CF"
      echo "    Added $API_DOMAIN to $CF"
    fi
  else
    echo "    !! Could not find the BiteChez Caddyfile. Add deploy/bitechez-caddy-block.txt to it by hand."
  fi
else
  echo "==> No BiteChez on this server: NeuroFit runs its own Caddy for HTTPS"
  docker network inspect neurofit_edge >/dev/null 2>&1 || docker network create neurofit_edge >/dev/null
  sed -i '/^EDGE_NETWORK=/d' .env && echo "EDGE_NETWORK=neurofit_edge" >> .env
  CADDY_PROFILE="--profile standalone"
fi

# 4. Build and start
echo "==> Building and starting NeuroFit"
docker compose $CADDY_PROFILE up -d --build

if [ -z "$CADDY_PROFILE" ] && [ -n "${CF:-}" ] && [ -f "$CF" ]; then
  docker compose -p bitechez exec -T caddy caddy reload --config /etc/caddy/Caddyfile >/dev/null 2>&1 \
    && echo "    BiteChez Caddy reloaded" \
    || echo "    !! Reload BiteChez Caddy by hand: cd $BITECHEZ_DIR && docker compose restart caddy"
fi

echo "==> Waiting for the API"
for _ in $(seq 1 40); do
  if docker compose exec -T neurofit-api wget -qO- http://127.0.0.1:5000/api/health >/dev/null 2>&1; then
    echo "    API is up. Check https://$API_DOMAIN/api/health in a browser (DNS: A record 'api' -> this server's IP)."
    exit 0
  fi
  sleep 3
done
echo "    !! API did not come up. See: docker compose logs neurofit-api"
exit 1
