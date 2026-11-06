#!/usr/bin/env bash
# Gera o .env com senhas aleatórias e cria as pastas de dados.
set -euo pipefail
cd "$(dirname "$0")"

if [ -f .env ]; then
  echo ".env já existe — nada foi alterado."
  echo "(Apague-o só se ainda não subiu o banco: as senhas ficam gravadas no MySQL.)"
  exit 0
fi

gen() { openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32; }

cp .env.example .env
sed -i "s|^MYSQL_PASSWORD=.*|MYSQL_PASSWORD=$(gen)|" .env
sed -i "s|^MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=$(gen)|" .env
chmod 600 .env

mkdir -p data/npm/data data/npm/letsencrypt data/mysql data/recordings

echo "✅ .env criado com senhas aleatórias (permissão 600)."
echo "   Revise TZ e GUAC_PATH no .env e depois rode: docker compose up -d"
