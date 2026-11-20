# autom.ato.br

Site do coletivo autom.ato.br, do Recife. Estética ASCII, sem dependências, sem rastreadores.

```
autom . ato . br
  |       |     |
  |       |     +-- o lugar: Brasil
  |       +-------- o ato: a ação, o gesto de quem escreve a regra
  +---------------- o autômato: a máquina que segue regras
```

## Estrutura

```
site/                          o que vai para o servidor
├── index.html                 abertura, obras, quem somos, contato
├── idioma.js                  troca entre PT, ES e EN
└── obras/
    └── derivadas-ao-vivo/
        └── index.html         a obra DERIVADAS AO VIVO
deploy/
├── nginx/autom.ato.br.conf    configuração do nginx
├── instalar-servidor.sh       instalação única no droplet
├── criar-usuario-deploy.sh    usuário restrito para a GitHub Action
└── publicar.sh                envia site/ para o droplet, à mão
.github/workflows/
└── publicar.yml               publica a cada push na main
```

Cada página é um único arquivo HTML, com CSS e JavaScript dentro. Para acrescentar uma obra, crie `site/obras/<nome>/index.html` e um cartão na seção "Obras" de `site/index.html`.

## Idiomas

O site fala português, espanhol e inglês. Cada texto aparece três vezes, com as classes `i-pt`, `i-es` e `i-en`, e o CSS mostra só a do idioma ativo:

```html
<p class="i-pt">Texto em português.</p>
<p class="i-es">Texto en español.</p>
<p class="i-en">Text in English.</p>
```

O `site/idioma.js` escolhe o idioma nesta ordem: `?lang=pt|es|en` no endereço, a escolha anterior da pessoa, o idioma do navegador e, por fim, português. Textos gerados por JavaScript usam `window.idioma.t({ pt: "...", es: "...", en: "..." })`. Para links diretos, use `https://autom.ato.br/?lang=en`.

## Rodar na sua máquina

```bash
cd site
python3 -m http.server 8000
```

Abra `http://localhost:8000`. A câmera da obra funciona em `localhost` e em `https`, não ao abrir o arquivo direto.

## Publicar pela primeira vez

### 1. GitHub

Na raiz deste repositório, com o [GitHub CLI](https://cli.github.com/) autenticado:

```bash
git init -b main
git add .
git commit -m "Primeira versão do site autom.ato.br"
gh repo create hdmabuse/autom.ato.br --public --source=. --push
```

### 2. DNS

Crie dois registros A apontando para `143.198.177.192`:

```
autom.ato.br      A   143.198.177.192
www.autom.ato.br  A   143.198.177.192
```

### 3. Servidor (uma vez só)

```bash
scp -r deploy root@143.198.177.192:/root/autom.ato.br-deploy
ssh root@143.198.177.192 'bash /root/autom.ato.br-deploy/instalar-servidor.sh'
```

O script:

- confere se o nginx está instalado no sistema;
- cria `/var/www/autom.ato.br`;
- acrescenta o site ao nginx sem tocar nos outros sites;
- roda `nginx -t` antes de recarregar e desfaz tudo se o teste falhar;
- pede o certificado HTTPS ao certbot quando o DNS já aponta para o droplet.

### 4. Enviar o site

```bash
bash deploy/publicar.sh
```

## Publicação automática com GitHub Actions

Depois de configurada, cada `git push` na branch `main` que mude algo em `site/` publica o site sozinho. O fluxo está em `.github/workflows/publicar.yml`. Ele também pode ser disparado à mão na aba Actions, em "Publicar site" > "Run workflow".

A Action entra no servidor com um usuário próprio, `deploy`. A chave desse usuário só escreve em `/var/www/autom.ato.br`. Ela não abre terminal e não tem `sudo`.

### 1. Criar uma chave só para publicar

Na sua máquina:

```bash
ssh-keygen -t ed25519 -N "" -C "github-actions-autom.ato.br" -f ~/.ssh/autom_deploy
```

Isso gera dois arquivos: `~/.ssh/autom_deploy` (privada) e `~/.ssh/autom_deploy.pub` (pública).

### 2. Criar o usuário `deploy` no servidor

```bash
scp deploy/criar-usuario-deploy.sh root@143.198.177.192:/root/
ssh root@143.198.177.192 "bash /root/criar-usuario-deploy.sh \"$(cat ~/.ssh/autom_deploy.pub)\""
```

No fim, o script imprime a linha para o segredo `DEPLOY_KNOWN_HOSTS`.

### 3. Cadastrar os segredos no GitHub

No repositório, em Settings > Secrets and variables > Actions > New repository secret:

| Segredo | Valor |
|---|---|
| `DEPLOY_HOST` | `143.198.177.192` |
| `DEPLOY_USER` | `deploy` |
| `DEPLOY_SSH_KEY` | o conteúdo de `~/.ssh/autom_deploy` (a chave privada inteira) |
| `DEPLOY_KNOWN_HOSTS` | a linha impressa pelo script do passo 2 |

Ou, com o GitHub CLI:

```bash
gh secret set DEPLOY_HOST --body "143.198.177.192"
gh secret set DEPLOY_USER --body "deploy"
gh secret set DEPLOY_SSH_KEY < ~/.ssh/autom_deploy
gh secret set DEPLOY_KNOWN_HOSTS --body "<linha impressa pelo script>"
```

O `DEPLOY_KNOWN_HOSTS` garante que a Action só envia o site para o seu servidor. Sem ele, a conexão é recusada.

### 4. Testar

Na aba Actions, rode "Publicar site" à mão. Depois disso, basta:

```bash
git add . && git commit -m "Descreva a mudança" && git push
```

## Publicar à mão

O `deploy/publicar.sh` continua funcionando, com o usuário `root`:

```bash
bash deploy/publicar.sh
```

No fim, ele devolve a posse da pasta ao usuário `deploy`, para a Action continuar conseguindo escrever.

## Pixelfed em Docker

O droplet também roda o Pixelfed. Se o Pixelfed estiver em Docker e o próprio container ocupar as portas 80 e 443, o nginx do sistema não consegue abrir essas portas e o `instalar-servidor.sh` para com um aviso. Nesse caso, o caminho é servir a pasta `/var/www/autom.ato.br` pelo proxy que já recebe o tráfego, com um bloco novo para `autom.ato.br`. Confira com:

```bash
sudo ss -ltnp | grep -E ':80 |:443 '
```

## Créditos

- *Derivadas de uma imagem* (1969): Waldemar Cordeiro e Giorgio Moscati.
- Releitura anterior: Marisangela de Sousa Lima, TCC em Design Digital, UFC Quixadá, 2025.

## Licença

A definir pelo coletivo.
