# Instalação — stack única (Docker Compose)

Um único `docker-compose.yml` sobe tudo: **Nginx Proxy Manager**, **Guacamole 1.6.0** com **MFA (TOTP)**, **guacd** e **MySQL**, com o schema do banco importado automaticamente. O que fica de fora é o que depende do seu ambiente: o DNS do domínio e o cadastro do Proxy Host no NPM (passo 4).

```
Internet ──443──▶ NPM ──▶ Guacamole (/acesso) ──▶ guacd ──▶ servidores internos
                  │        1º fator: usuário/senha        RDP / SSH / VNC
                  │        2º fator: TOTP                 3º: login da máquina
                  └ único ponto exposto
```

## O que mudou em relação à instalação anterior

| Antes | Agora |
|---|---|
| Guacamole, MySQL e NPM em estruturas separadas | Um compose só, com três redes isoladas |
| `initdb.sql` gerado e importado à mão | Gerado e importado sozinho no primeiro start |
| Porta 8080 publicada no host (dependia do `ufw deny`) | Guacamole **não publica porta**; só o NPM alcança |
| Senhas fixas no compose | `.env` com senhas aleatórias (`setup.sh`) |
| MFA instalado à parte | TOTP ligado por variável (`TOTP_ENABLED`) |
| Logs com o IP do proxy | IP real do cliente via `X-Forwarded-For` (RemoteIpValve) |
| — | Bloqueio de força bruta por IP (extensão `ban`) |
| — | Gravações de sessão visíveis no Histórico |

### Redes

- `sa-edge`: NPM ↔ Guacamole.
- `sa-backend` (*internal*, sem saída): Guacamole ↔ guacd ↔ MySQL. O banco não fala com a internet nem com o NPM.
- `sa-lan`: só o guacd, para alcançar as máquinas da rede interna.

## 1. Pré-requisitos

Docker Engine com o plugin Compose v2 (`docker compose`, com espaço):

```bash
curl -fsSL https://get.docker.com | sudo sh
docker compose version
```

Firewall: abra apenas 80 e 443.

```bash
sudo ufw allow 80,443/tcp
```

## 2. Configurar

```bash
git clone https://github.com/Jarderl/guam-remote-desktop.git
cd guam-remote-desktop
bash setup.sh
nano .env      # ajuste TZ e, se quiser, GUAC_PATH
```

## 3. Subir

```bash
docker compose up -d
docker compose ps
```

No primeiro start, `sa-guac-init` aparece como *exited (0)*, e isso é o esperado: ele gera o schema e sai. O MySQL leva de 30 a 60 s para importar; o Guacamole só sobe depois que o banco fica *healthy*.

Para acompanhar: `docker compose logs -f db guacamole`.

## 4. Configurar o domínio no NPM

O painel do NPM fica preso ao `127.0.0.1:81`. Do seu computador:

```bash
ssh -L 8181:127.0.0.1:81 usuario@SEU_SERVIDOR
```

Abra `http://localhost:8181` (primeiro acesso: `admin@example.com` / `changeme`, e o NPM pede a troca na hora).

Em **Hosts → Proxy Hosts → Add Proxy Host**:

- **Details**: Domain Names = seu domínio · Scheme `http` · Forward Hostname `guacamole` · Forward Port `8080` · marque **Websockets Support** e **Block Common Exploits**.
- **SSL**: Request a new SSL Certificate · **Force SSL** · **HTTP/2** · **HSTS**.
- **Advanced**: cole o conteúdo de [`nginx/npm-advanced-guacamole.conf`](nginx/npm-advanced-guacamole.conf).

Use o bloco do **Advanced** em vez da aba *Custom locations*: a aba não permite `proxy_buffering off` nem os timeouts longos, e sem eles as sessões RDP travam ou caem.

Se trocar `GUAC_PATH` no `.env`, troque também os dois `location` do arquivo: o caminho do NPM e o do Guacamole precisam ser iguais, porque não há reescrita de URL (com isso, cookie e WebSocket funcionam sem ajuste).

## 5. Primeiro acesso e MFA

1. Acesse `https://SEU_DOMINIO/acesso/` e entre com `guacadmin` / `guacadmin`.
2. O Guacamole exige o cadastro do TOTP na hora: leia o QR Code no app autenticador e confirme o código.
3. Em **Configurações → Usuários**, crie seu usuário administrador (todas as permissões), saia, entre com ele (vai cadastrar o TOTP dele também) e **apague o `guacadmin`**.
4. Cadastre as conexões em **Configurações → Conexões** (RDP/SSH/VNC). O hostname é o IP da máquina na rede interna: quem conecta é o guacd.

### Gravação de sessão (opcional, por conexão)

Na conexão, seção **Gravação de tela**:

- Caminho: `${HISTORY_PATH}/${HISTORY_UUID}`
- Marque **Criar automaticamente o caminho de gravação**.

A gravação aparece em **Configurações → Histórico** e pode ser reproduzida no navegador. Os arquivos ficam em `./data/recordings` (gravações de RDP ocupam espaço, então monitore).

### Se alguém perder o celular do TOTP

Um administrador abre o usuário em **Configurações → Usuários** e desmarca **TOTP key confirmed**: no próximo login, o usuário cadastra de novo.

## Operação

| Tarefa | Comando |
|---|---|
| Ver estado | `docker compose ps` |
| Logs | `docker compose logs -f guacamole` |
| Atualizar | ajuste `GUAC_VERSION` no `.env` → `docker compose pull && docker compose up -d` |
| Backup do banco | `docker compose exec db sh -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction "$MYSQL_DATABASE"' > backup-$(date +%F).sql` |
| Backup completo | parar a stack e copiar `./data` e `.env` |

Ao atualizar o Guacamole entre versões, confira nas notas de versão se há script de *upgrade* do schema: o import automático só roda com o banco vazio.

## Já tem um NPM rodando em outro compose?

Remova o serviço `npm` deste arquivo e ligue o Guacamole na rede do seu NPM:

```yaml
# em services.guacamole.networks, troque "edge" por:
      - npm_default        # nome da rede do seu NPM (docker network ls)

networks:
  npm_default:
    external: true
```

## Solução de problemas

- **Tela branca ou "conexão perdida" logo ao abrir a máquina**: faltou o bloco do *Advanced* (sem `proxy_buffering off` ou sem os cabeçalhos de WebSocket).
- **404 do Tomcat**: o caminho do NPM difere de `GUAC_PATH`.
- **Guacamole não sobe e o `db` não fica healthy**: `docker compose logs db`. Se o `.env` foi recriado depois do primeiro start, a senha nova não bate com a gravada no banco; em instalação nova, apague `./data/mysql` e suba de novo.
- **Histórico mostra o IP do proxy**: o NPM precisa enviar `X-Forwarded-For` (o bloco do *Advanced* já envia).
