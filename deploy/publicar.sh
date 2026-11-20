#!/usr/bin/env bash
# Publica a pasta site/ no droplet.
# Rode NA SUA MAQUINA, na raiz do repositorio:
#   bash deploy/publicar.sh
#
# Use outro usuario ou endereco assim:
#   SERVIDOR=mabuse@143.198.177.192 bash deploy/publicar.sh

set -euo pipefail

SERVIDOR="${SERVIDOR:-root@143.198.177.192}"
DESTINO="/var/www/autom.ato.br/"
RAIZ_REPO="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$RAIZ_REPO/site/index.html" ]]; then
  echo "Nao encontrei site/index.html. Rode a partir do repositorio." >&2
  exit 1
fi

echo "Enviando site/ para ${SERVIDOR}:${DESTINO}"
rsync -avz --delete \
  --exclude ".*" \
  --chmod=D755,F644 \
  "$RAIZ_REPO/site/" "${SERVIDOR}:${DESTINO}"

# Se o usuario deploy existe, devolve a posse da pasta a ele,
# para a GitHub Action continuar conseguindo escrever.
ssh "$SERVIDOR" 'id deploy >/dev/null 2>&1 && chown -R deploy:www-data /var/www/autom.ato.br || true'

echo "Publicado."
