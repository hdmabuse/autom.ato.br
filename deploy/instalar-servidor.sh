#!/usr/bin/env bash
# Instalacao unica do autom.ato.br no droplet.
# Rode NO SERVIDOR, como root:
#   sudo bash instalar-servidor.sh
#
# O script nao mexe na configuracao do Pixelfed nem de outros sites.
# Ele so acrescenta um site novo ao nginx e testa antes de recarregar.

set -euo pipefail

DOMINIO="autom.ato.br"
RAIZ="/var/www/${DOMINIO}"
CONF_ORIGEM="$(dirname "$0")/nginx/${DOMINIO}.conf"
CONF_DESTINO="/etc/nginx/sites-available/${DOMINIO}"
IP_ESPERADO="143.198.177.192"

if [[ $EUID -ne 0 ]]; then
  echo "Rode como root: sudo bash $0" >&2
  exit 1
fi

# 1. O nginx precisa estar instalado direto no sistema.
if ! command -v nginx >/dev/null 2>&1; then
  echo "nginx nao encontrado no sistema."
  echo "Se o Pixelfed roda em Docker e ocupa as portas 80/443, este script nao serve."
  echo "Veja a secao 'Pixelfed em Docker' no README antes de seguir."
  exit 1
fi

if [[ ! -d /etc/nginx/sites-available ]]; then
  echo "Este nginx nao usa sites-available/sites-enabled. Ajuste o caminho no script." >&2
  exit 1
fi

# 2. Pasta do site.
mkdir -p "$RAIZ"
chown -R www-data:www-data "$RAIZ"
echo "Pasta do site: $RAIZ"

# 3. Configuracao do nginx.
if [[ -e "$CONF_DESTINO" ]]; then
  echo "Ja existe $CONF_DESTINO. Vou manter o arquivo atual."
else
  cp "$CONF_ORIGEM" "$CONF_DESTINO"
  echo "Configuracao copiada para $CONF_DESTINO"
fi
ln -sf "$CONF_DESTINO" "/etc/nginx/sites-enabled/${DOMINIO}"

# 4. Testa antes de recarregar. Se falhar, desfaz o link e para.
if ! nginx -t; then
  echo "nginx -t falhou. Removendo o link para nao derrubar os outros sites." >&2
  rm -f "/etc/nginx/sites-enabled/${DOMINIO}"
  exit 1
fi
systemctl reload nginx
echo "nginx recarregado."

# 5. HTTPS com certbot, so se o DNS ja aponta para este servidor.
IP_DNS="$(getent ahostsv4 "$DOMINIO" | awk 'NR==1{print $1}' || true)"
if [[ "$IP_DNS" != "$IP_ESPERADO" ]]; then
  echo
  echo "O DNS de $DOMINIO ainda nao aponta para $IP_ESPERADO (resposta: '${IP_DNS:-nenhuma}')."
  echo "Quando apontar, rode:"
  echo "  certbot --nginx -d $DOMINIO -d www.$DOMINIO"
  exit 0
fi

if ! command -v certbot >/dev/null 2>&1; then
  apt-get update -q
  apt-get install -y -q certbot python3-certbot-nginx
fi
certbot --nginx -d "$DOMINIO" -d "www.$DOMINIO" --redirect
echo "Pronto: https://$DOMINIO"
