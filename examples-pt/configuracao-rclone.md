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
# Executar configuração do rclone em container temporário
docker run --rm -it -v rclone_config:/root/.config/rclone rclone/rclone:latest config
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

1. Uma janela do navegador abrirá (ou você receberá uma URL para visitar)
2. Faça login na sua conta Google
3. Conceda permissões ao Rclone
4. Copie o código de autorização de volta para o terminal

## Passo 5: Completar Configuração

1. **Configurar como team drive**: Digite `n` e pressione Enter
2. **ID do Shared drive (Team Drive)**: Pressione Enter (deixar em branco)
3. **Configuração completa**: Digite `y` e pressione Enter

## Passo 6: Testar Configuração

```bash
# Testar a configuração
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest lsd gdrive:
```

Você deve ver suas pastas do Google Drive listadas.

## Passo 7: Criar Diretório de Backup (Opcional)

```bash
# Criar diretório de backups no Google Drive
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest mkdir gdrive:backups
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
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest listremotes

# Testar conexão
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest about gdrive:

# Listar arquivos
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest ls gdrive:

# Criar diretório
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest mkdir gdrive:backups

# Deletar diretório (cuidado!)
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest rmdir gdrive:backups
```

## Notas de Segurança

- Nunca commite seu arquivo `rclone.conf` no controle de versão
- Use Docker secrets em produção para configuração sensível
- Rotacione regularmente suas credenciais da API do Google Drive
- Considere usar service accounts para ambientes de produção

## Próximos Passos

Uma vez que o Rclone esteja configurado, você pode prosseguir com o deploy do seu container de backup MySQL usando as configurações Docker Compose ou Docker Swarm fornecidas.
