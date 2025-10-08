# 🚀 Guia Rápido - MySQL Backup Rclone

## 📋 Passo a Passo Completo

### **1. Configurar Rclone (UMA VEZ)**

```bash
# Criar volume para configuração
docker volume create rclone_config

# Entrar no container para configurar
docker run --rm -it --entrypoint bash -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest

# Dentro do container, execute:
rclone config

# Siga as instruções:
# n (new remote)
# gdrive (nome)
# drive (tipo do storage)
# [Enter] para Client ID (deixar em branco)
# [Enter] para Client Secret (deixar em branco)
# [Enter] para Scope (usar padrão)
# [Enter] para Service Account (deixar em branco)
# n para Advanced config
# y para Auto config
# 
# ⚠️ AUTENTICAÇÃO: O rclone mostrará um comando como:
# rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"
# 
# Execute esse comando na SUA MÁQUINA LOCAL (não no container):
# 1. Instale rclone local: https://rclone.org/downloads/
# 2. COPIE o comando EXATO que apareceu no seu terminal (cada config tem código único!)
# 3. Execute o comando copiado na sua máquina local
# 4. Autentique com Google no navegador que abrirá
# 5. Copie o token JSON gerado
# 6. Cole no container e pressione Enter
#
# n para Team Drive
# [Enter] para Shared Drive ID
# y para confirmar

# Sair do container:
exit
```

### **2. Testar Configuração**

```bash
# Listar pastas do Google Drive
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest lsd gdrive:

# Criar pasta de backups
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest mkdir gdrive:backups
```

### **3. Executar Container de Backup**

```bash
# Rodar backup (substitua com suas informações)
docker run -d \
  --name mysql-backup \
  --restart unless-stopped \
  -e MYSQL_HOST=seu-mysql-host \
  -e MYSQL_PORT=3306 \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=sua-senha \
  -e MYSQL_DATABASES=banco1,banco2,banco3 \
  -e RCLONE_REMOTE=gdrive:backups/mysql \
  -e CRON_SCHEDULE="0 2 * * *" \
  -e BACKUP_RETENTION=7 \
  -e TZ=America/Sao_Paulo \
  -v rclone_config:/root/.config/rclone \
  alian87/mysql-backup-rclone:latest
```

### **4. Verificar Logs**

```bash
# Ver logs do container
docker logs mysql-backup

# Acompanhar logs em tempo real
docker logs -f mysql-backup
```

### **5. Testar Backup Manual**

```bash
# Executar backup manualmente
docker exec mysql-backup /scripts/backup.sh
```

## 🔧 Comandos Úteis

### **Gerenciamento do Container**

```bash
# Ver status
docker ps | grep mysql-backup

# Parar container
docker stop mysql-backup

# Iniciar container
docker start mysql-backup

# Reiniciar container
docker restart mysql-backup

# Remover container
docker rm -f mysql-backup
```

### **Comandos Rclone**

```bash
# Listar remotos configurados
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest listremotes

# Ver informações do Google Drive
docker run --rm --entrypoint rclone -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest about gdrive:

# Listar backups no Google Drive
docker exec mysql-backup rclone ls gdrive:backups/mysql

# Baixar backup específico
docker exec mysql-backup rclone copy gdrive:backups/mysql/2025-01-07_02-00-00 /tmp/restore
```

### **Monitoramento**

```bash
# Ver resumo dos backups
docker logs mysql-backup | grep "Backup Summary"

# Ver apenas erros
docker logs mysql-backup | grep ERROR

# Verificar saúde do container
docker inspect mysql-backup | grep -A 5 Health

# Ver uso de recursos
docker stats mysql-backup
```

## ⚙️ Configurações Comuns

### **Backup Diário às 3h**
```bash
-e CRON_SCHEDULE="0 3 * * *"
```

### **Backup a Cada 6 Horas**
```bash
-e CRON_SCHEDULE="0 */6 * * *"
```

### **Manter 14 Backups Locais**
```bash
-e BACKUP_RETENTION=14
```

### **Com Notificações Slack**
```bash
-e WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

## 🐳 Usando Docker Compose

### **1. Criar docker-compose.yml**

```yaml
version: '3.8'

services:
  mysql-backup:
    image: alian87/mysql-backup-rclone:latest
    container_name: mysql-backup
    restart: unless-stopped
    environment:
      MYSQL_HOST: "mysql"
      MYSQL_PORT: 3306
      MYSQL_USER: "root"
      MYSQL_PASSWORD: "sua-senha"
      MYSQL_DATABASES: "banco1,banco2"
      RCLONE_REMOTE: "gdrive:backups/mysql"
      CRON_SCHEDULE: "0 2 * * *"
      BACKUP_RETENTION: 7
      TZ: "America/Sao_Paulo"
    volumes:
      - rclone_config:/root/.config/rclone
      - backup_data:/backup

volumes:
  rclone_config:
  backup_data:
```

### **2. Executar**

```bash
# Iniciar
docker-compose up -d

# Ver logs
docker-compose logs -f mysql-backup

# Parar
docker-compose down
```

## 🚨 Troubleshooting Rápido

### **Erro: "MYSQL_DATABASES is not set"**
```bash
# Definir variável de ambiente
-e MYSQL_DATABASES="seu_banco"
```

### **Erro: "Cannot connect to MySQL"**
```bash
# Verificar conectividade
docker exec mysql-backup mysql -h seu-host -u root -p -e "SELECT 1"
```

### **Erro: "Rclone configuration not found"**
```bash
# Reconfigurar rclone
docker run --rm -it --entrypoint bash -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest
# Dentro: rclone config
```

## 📞 Suporte

- 📖 Documentação completa: [README-pt.md](README-pt.md)
- 🐛 Reportar problemas: [GitHub Issues](https://github.com/alian87/mysql-backup-rclone/issues)
- 💬 Discussões: [GitHub Discussions](https://github.com/alian87/mysql-backup-rclone/discussions)

---

**Este guia cobre os cenários mais comuns. Para informações detalhadas, consulte a [documentação completa](README-pt.md).**
