# 🔧 Guia de Solução de Problemas

Este guia ajuda você a diagnosticar e resolver problemas comuns com o container MySQL Backup Rclone.

## 🚨 Problemas Comuns

### Container Não Inicia

#### Sintomas
- Container sai imediatamente
- Sem logs ou logs vazios
- Docker mostra status "Exited"

#### Diagnóstico
```bash
# Verificar logs do container
docker logs mysql-backup

# Verificar status do container
docker ps -a | grep mysql-backup

# Verificar eventos do Docker
docker events --since 1h | grep mysql-backup
```

#### Causas Comuns e Soluções

**1. Configuração do Rclone Ausente**
```
Erro: Rclone configuration not found at /root/.config/rclone/rclone.conf
```
**Solução:**
```bash
# Criar e configurar volume do rclone
docker volume create rclone_config
docker run --rm -it -v rclone_config:/root/.config/rclone rclone/rclone:latest config
```

**2. Variáveis de Ambiente Inválidas**
```
Erro: MYSQL_DATABASES is not set
```
**Solução:**
```bash
# Verificar variáveis de ambiente
docker exec mysql-backup env | grep MYSQL

# Definir variáveis obrigatórias
docker run -e MYSQL_DATABASES="db1,db2" ... mysql-backup-rclone
```

**3. Problemas de Conectividade de Rede**
```
Erro: Cannot connect to MySQL
```
**Solução:**
```bash
# Testar conectividade MySQL
docker exec mysql-backup mysql -h mysql-host -u user -p -e "SELECT 1"

# Verificar configuração de rede
docker network ls
docker network inspect network_name
```

### Falhas de Backup

#### Sintomas
- Processo de backup inicia mas falha
- Mensagens de erro nos logs
- Nenhum arquivo de backup criado

#### Diagnóstico
```bash
# Verificar logs de backup
docker logs mysql-backup | grep -i error

# Verificar logs do cron
docker exec mysql-backup cat /var/log/cron.log

# Habilitar logging de debug
docker run -e LOG_LEVEL=DEBUG ... mysql-backup-rclone
```

#### Causas Comuns e Soluções

**1. Problemas de Conexão MySQL**
```
Erro: Cannot connect to MySQL
Host: mysql:3306 | User: root
```
**Solução:**
```bash
# Testar conexão MySQL manualmente
docker exec mysql-backup mysql -h mysql-host -P 3306 -u root -p'senha' -e "SELECT 1"

# Verificar status do servidor MySQL
docker ps | grep mysql
docker logs mysql-server

# Verificar conectividade de rede
docker exec mysql-backup ping mysql-host
```

**2. Banco de Dados Não Encontrado**
```
Erro: Unknown database 'nome_do_banco'
```
**Solução:**
```bash
# Listar bancos disponíveis
docker exec mysql-backup mysql -h mysql-host -u user -p -e "SHOW DATABASES"

# Atualizar variável MYSQL_DATABASES
docker run -e MYSQL_DATABASES="banco_correto1,banco_correto2" ... mysql-backup-rclone
```

**3. Permissão Negada**
```
Erro: Access denied for user 'backup_user'@'%'
```
**Solução:**
```sql
-- Conceder permissões necessárias
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup_user'@'%';
FLUSH PRIVILEGES;
```

### Falhas de Upload

#### Sintomas
- Arquivos de backup criados localmente mas não enviados
- Erros do Rclone nos logs
- Google Drive não mostra arquivos novos

#### Diagnóstico
```bash
# Testar configuração do rclone
docker exec mysql-backup rclone lsd gdrive:

# Verificar informações do rclone
docker exec mysql-backup rclone about gdrive:

# Testar upload manualmente
docker exec mysql-backup rclone copy /backup/test gdrive:test-backup
```

#### Causas Comuns e Soluções

**1. Problemas de Configuração do Rclone**
```
Erro: Failed to create file system for "gdrive:": didn't find section in config file
```
**Solução:**
```bash
# Reconfigurar rclone
docker run --rm -it -v rclone_config:/root/.config/rclone rclone/rclone:latest config

# Testar configuração
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest lsd gdrive:
```

**2. Problemas da API do Google Drive**
```
Erro: failed to get drive: googleapi: Error 403: Access Not Configured
```
**Solução:**
- Habilitar API do Google Drive no Google Cloud Console
- Verificar cotas e limites da API
- Verificar credenciais OAuth2

**3. Armazenamento Insuficiente**
```
Erro: googleapi: Error 403: The user's Drive storage quota has been exceeded
```
**Solução:**
```bash
# Verificar uso do Google Drive
docker exec mysql-backup rclone about gdrive:

# Limpar backups antigos
docker exec mysql-backup rclone delete gdrive:backups/pasta-backup-antiga
```

### Problemas com Job Cron

#### Sintomas
- Container de backup executa mas nenhum backup agendado
- Logs do cron vazios
- Backup manual funciona mas agendado não

#### Diagnóstico
```bash
# Verificar status do cron
docker exec mysql-backup pgrep cron

# Verificar configuração do cron
docker exec mysql-backup crontab -l

# Verificar logs do cron
docker exec mysql-backup cat /var/log/cron.log
```

#### Causas Comuns e Soluções

**1. Cron Não Está Executando**
```
Erro: No cron process found
```
**Solução:**
```bash
# Reiniciar container
docker restart mysql-backup

# Verificar serviço cron
docker exec mysql-backup service cron status
```

**2. Agendamento Cron Inválido**
```
Erro: Invalid cron expression
```
**Solução:**
```bash
# Usar expressão cron válida
# Exemplos:
# "0 2 * * *" - Diariamente às 2h
# "0 */6 * * *" - A cada 6 horas
# "0 0 1 * *" - Mensalmente no dia 1

# Testar expressão cron
docker run --rm alpine sh -c 'echo "0 2 * * *" | crontab -'
```

**3. Problemas de Permissão**
```
Erro: Permission denied
```
**Solução:**
```bash
# Verificar permissões de arquivo
docker exec mysql-backup ls -la /scripts/
docker exec mysql-backup ls -la /var/log/cron.log

# Corrigir permissões se necessário
docker exec mysql-backup chmod +x /scripts/backup.sh
```

## 🔍 Técnicas de Debug

### Habilitar Logging de Debug

```bash
# Executar com logging de debug
docker run -e LOG_LEVEL=DEBUG ... mysql-backup-rclone

# Ou atualizar container existente
docker run -e LOG_LEVEL=DEBUG --rm mysql-backup-rclone /scripts/backup.sh
```

### Testes Manuais

```bash
# Testar conexão MySQL
docker exec mysql-backup mysql -h mysql-host -u user -p -e "SELECT 1"

# Testar conexão rclone
docker exec mysql-backup rclone lsd gdrive:

# Testar script de backup manualmente
docker exec mysql-backup /scripts/backup.sh

# Testar job cron manualmente
docker exec mysql-backup bash -c "echo 'test' | crontab -"
```

### Diagnóstico de Rede

```bash
# Verificar conectividade de rede
docker exec mysql-backup ping mysql-host
docker exec mysql-backup nslookup mysql-host

# Verificar conectividade de porta
docker exec mysql-backup nc -zv mysql-host 3306

# Verificar resolução DNS
docker exec mysql-backup nslookup google.com
```

### Monitoramento de Recursos

```bash
# Verificar recursos do container
docker stats mysql-backup

# Verificar uso de disco
docker exec mysql-backup df -h
docker exec mysql-backup du -sh /backup/*

# Verificar uso de memória
docker exec mysql-backup free -h
```

## 📊 Problemas de Performance

### Backups Lentos

#### Sintomas
- Backup demora muito para completar
- Alto uso de CPU durante backup
- Erros de timeout

#### Soluções

**1. Otimizar Dump MySQL**
```bash
# Já incluído no backup.sh:
# --single-transaction (para InnoDB)
# --quick (para tabelas grandes)
# --routines --triggers --events (para backup completo)
```

**2. Otimizar Upload do Rclone**
```bash
# Adicionar ao comando rclone no backup.sh:
rclone copy ... --transfers=4 --checkers=8 --drive-chunk-size=64M
```

**3. Usar Armazenamento SSD**
```bash
# Montar volume SSD para diretório de backup
docker run -v /ssd/backups:/backup ... mysql-backup-rclone
```

### Alto Uso de Memória

#### Sintomas
- Container usa memória excessiva
- Erros de falta de memória
- Lentidão do sistema

#### Soluções

**1. Limitar Recursos do Container**
```yaml
# docker-compose.yml
services:
  mysql-backup:
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
```

**2. Otimizar Processo de Backup**
```bash
# Usar backup streaming para bancos grandes
mysqldump ... | gzip | rclone rcat gdrive:backup.sql.gz
```

## 🔧 Manutenção

### Tarefas de Manutenção Regular

```bash
# Verificar status do backup
docker logs mysql-backup | grep "Backup Summary"

# Verificar uploads do Google Drive
docker exec mysql-backup rclone ls gdrive:backups

# Limpar backups locais antigos
docker exec mysql-backup ls -la /backup/

# Verificar saúde do container
docker ps | grep mysql-backup
```

### Script de Monitoramento

```bash
#!/bin/bash
# backup-monitor.sh

CONTAINER_NAME="mysql-backup"
LOG_FILE="/var/log/backup-monitor.log"

# Verificar se container está executando
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "$(date): Container $CONTAINER_NAME não está executando" >> $LOG_FILE
    # Enviar alerta
fi

# Verificar último backup
LAST_BACKUP=$(docker logs $CONTAINER_NAME 2>&1 | grep "Backup completed" | tail -1)
if [ -z "$LAST_BACKUP" ]; then
    echo "$(date): Nenhum backup recente encontrado" >> $LOG_FILE
    # Enviar alerta
fi

# Verificar uso de disco
DISK_USAGE=$(docker exec $CONTAINER_NAME df -h /backup | awk 'NR==2{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "$(date): Alto uso de disco: ${DISK_USAGE}%" >> $LOG_FILE
    # Enviar alerta
fi
```

## 📞 Obtendo Ajuda

### Antes de Pedir Ajuda

1. **Verificar os logs**: `docker logs mysql-backup`
2. **Habilitar logging de debug**: `LOG_LEVEL=DEBUG`
3. **Testar conectividade**: Testes manuais MySQL e rclone
4. **Verificar configuração**: Verificar todas as variáveis de ambiente
5. **Revisar este guia**: Procurar por problemas similares

### Informações para Fornecer

Ao pedir ajuda, inclua:

- Versão do Docker: `docker --version`
- Logs do container: `docker logs mysql-backup`
- Configuração: Variáveis de ambiente (sem senhas)
- Mensagens de erro: Texto exato do erro
- Passos para reproduzir: O que você fez antes do erro

### Canais de Suporte

- 📖 [Documentação](README-pt.md)
- 🐛 [Issues do GitHub](https://github.com/alian87/mysql-backup-rclone/issues)
- 💬 [Discussões do GitHub](https://github.com/alian87/mysql-backup-rclone/discussions)
- 📧 [Suporte por Email](mailto:alian.v.p.87@gmail.com)
