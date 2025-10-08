# Guia de Configuração do Rclone

Este guia ajudará você a configurar o Rclone para funcionar com o Google Drive para seus backups MySQL.

## Pré-requisitos

- Docker instalado
- Conta Google com acesso ao Drive
- Conhecimento básico de linha de comando

## Passo 1: Criar Volume do Rclone

```bash
# Criar um volume Docker para configuração do rclone
docker volume create rclone_config
```

## Passo 2: Configurar Rclone

```bash
# Executar configuração do rclone em container temporário usando a imagem de backup
docker run --rm -it --entrypoint bash -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest

# Dentro do container, execute:
# rclone config
```

## Passo 3: Seguir o Assistente de Configuração

Quando solicitado, siga estes passos:

1. **Criar novo remoto**: Digite `n` e pressione Enter
2. **Nome**: Digite `gdrive` e pressione Enter
3. **Tipo de armazenamento**: Digite `drive` e pressione Enter
4. **Client ID**: Pressione Enter (deixar em branco para padrão)
5. **Client Secret**: Pressione Enter (deixar em branco para padrão)
6. **Escopo**: Pressione Enter (usar padrão)
7. **Arquivo de Service Account**: Pressione Enter (deixar em branco)
8. **Config avançada**: Digite `n` e pressione Enter
9. **Usar auto config**: Digite `y` e pressione Enter

## Passo 4: Autenticar com Google

⚠️ **Importante**: Como você está dentro de um container, precisa usar uma máquina local com rclone instalado e navegador web disponível.

### 4.1. O rclone mostrará algo assim:

```
Option config_token.
For this to work, you will need rclone available on a machine that has
a web browser available.
For more help and alternate methods see: https://rclone.org/remote_setup/
Execute the following on the machine with the web browser (same rclone
version recommended):
        rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"
Then paste the result.
Enter a value.
config_token>
```

⚠️ **IMPORTANTE**: O código `"eyJzY29wZSI6ImRyaXZlIn0"` acima é apenas um **exemplo**. Cada configuração gera um código único. **Use o código EXATO que aparecer no seu terminal!**

### 4.2. Instalar rclone na sua máquina local (se ainda não tiver):

**Windows:**
```powershell
# Usando chocolatey
choco install rclone

# OU baixar manualmente de: https://rclone.org/downloads/
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt install rclone

# OU
curl https://rclone.org/install.sh | sudo bash
```

**macOS:**
```bash
brew install rclone
```

### 4.3. Executar o comando de autorização:

1. **Copie o comando COMPLETO** que apareceu no container (algo como: `rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"`)
   - ⚠️ **Não use o exemplo acima!** Copie o comando exato do seu terminal
2. **Execute na sua máquina local** (fora do container) o comando que você copiou
3. Uma **janela do navegador abrirá automaticamente**
4. **Faça login** na sua conta Google
5. **Autorize** o acesso ao Google Drive
6. O terminal mostrará um **token** (um código JSON longo)

### 4.4. Colar o token de volta no container:

1. **Copie todo o token** que apareceu na sua máquina local (começa com `{` e termina com `}`)
2. **Cole no terminal do container** onde está esperando o `config_token>`
3. Pressione Enter

## Passo 5: Completar Configuração

1. **Configurar como team drive**: Digite `n` e pressione Enter
2. **ID do Shared drive (Team Drive)**: Pressione Enter (deixar em branco)
3. **Configuração completa**: Digite `y` e pressione Enter

## Passo 6: Testar Configuração

```bash
# Testar a configuração
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest lsd gdrive:
```

Você deve ver suas pastas do Google Drive listadas.

## Passo 7: Criar Diretório de Backup (Opcional)

```bash
# Criar diretório de backups no Google Drive
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest mkdir gdrive:backups
```

## Alternativa: Configuração Manual

Se preferir configurar o rclone manualmente, você pode criar o arquivo de configuração diretamente:

```bash
# Criar diretório de configuração
docker run --rm -v rclone_config:/root/.config/rclone alpine mkdir -p /root/.config/rclone

# Criar arquivo de configuração (substitua com sua config real)
docker run --rm -v rclone_config:/root/.config/rclone alpine sh -c 'cat > /root/.config/rclone/rclone.conf << EOF
[gdrive]
type = drive
client_id = 
client_secret = 
scope = drive
root_folder_id = 
service_account_file = 
EOF'
```

## Solução de Problemas

### Problemas Comuns

1. **Falha na autenticação**: Certifique-se de estar usando a conta Google correta
2. **Permissão negada**: Verifique se você tem acesso de escrita ao Google Drive
3. **Problemas de rede**: Certifique-se de que seu container pode acessar a internet

### Comandos Úteis

```bash
# Listar remotos
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest listremotes

# Testar conexão
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest about gdrive:

# Listar arquivos
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest ls gdrive:

# Criar diretório
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest mkdir gdrive:backups

# Deletar diretório (cuidado!)
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest rmdir gdrive:backups
```

## Notas de Segurança

- Nunca commite seu arquivo `rclone.conf` no controle de versão
- Use Docker secrets em produção para configuração sensível
- Rotacione regularmente suas credenciais da API do Google Drive
- Considere usar service accounts para ambientes de produção

## Próximos Passos

Uma vez que o Rclone esteja configurado, você pode prosseguir com o deploy do seu container de backup MySQL usando as configurações Docker Compose ou Docker Swarm fornecidas.
