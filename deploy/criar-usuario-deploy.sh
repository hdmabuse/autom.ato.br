#!/usr/bin/env bash
# Cria o usuario "deploy", que a GitHub Action usa para publicar o site.
# Rode NO SERVIDOR, como root, depois do instalar-servidor.sh:
#   sudo bash criar-usuario-deploy.sh "ssh-ed25519 AAAA... github-actions-autom.ato.br"
#
# A chave so consegue escrever em /var/www/autom.ato.br, por meio do rrsync.
# Ela nao abre shell, nao encaminha portas e nao tem sudo.

set -euo pipefail

USUARIO="deploy"
RAIZ="/var/www/autom.ato.br"
CHAVE_PUBLICA="${1:-}"

if [[ $EUID -ne 0 ]]; then
  echo "Rode como root: sudo bash $0 \"<chave publica>\"" >&2
  exit 1
fi
if [[ -z "$CHAVE_PUBLICA" || "$CHAVE_PUBLICA" != ssh-* ]]; then
  echo "Passe a chave PUBLICA entre aspas (comeca com ssh-ed25519)." >&2
  exit 1
fi

# rsync e rrsync
if ! command -v rsync >/dev/null 2>&1; then
  apt-get update -q && apt-get install -y -q rsync
fi
RRSYNC="$(command -v rrsync || true)"
if [[ -z "$RRSYNC" && -f /usr/share/doc/rsync/scripts/rrsync ]]; then
  install -m 755 /usr/share/doc/rsync/scripts/rrsync /usr/local/bin/rrsync
  RRSYNC="/usr/local/bin/rrsync"
fi
if [[ -z "$RRSYNC" ]]; then
  echo "Nao encontrei o rrsync. Atualize o pacote rsync e rode de novo." >&2
  exit 1
fi

# Usuario sem senha e sem sudo.
if ! id "$USUARIO" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "Publicacao do site autom.ato.br" "$USUARIO"
fi

# A pasta do site passa a pertencer ao usuario deploy.
mkdir -p "$RAIZ"
chown -R "$USUARIO":www-data "$RAIZ"
chmod 755 "$RAIZ"

# Chave restrita ao rrsync, com escrita so na pasta do site.
install -d -m 700 -o "$USUARIO" -g "$USUARIO" "/home/$USUARIO/.ssh"
LINHA="command=\"$RRSYNC $RAIZ\",restrict $CHAVE_PUBLICA"
AUTH="/home/$USUARIO/.ssh/authorized_keys"
touch "$AUTH"
if ! grep -qF "$CHAVE_PUBLICA" "$AUTH"; then
  echo "$LINHA" >> "$AUTH"
fi
chown "$USUARIO":"$USUARIO" "$AUTH"
chmod 600 "$AUTH"

echo "Usuario $USUARIO pronto. A chave so escreve em $RAIZ."
echo
echo "Linha para o segredo DEPLOY_KNOWN_HOSTS:"
for f in /etc/ssh/ssh_host_ed25519_key.pub; do
  [[ -f "$f" ]] && echo "143.198.177.192 $(cut -d' ' -f1,2 "$f")"
done
