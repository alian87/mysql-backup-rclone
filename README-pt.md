# 🗄️ MySQL Backup com Rclone

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Google Drive](https://img.shields.io/badge/Google%20Drive-4285F4?style=for-the-badge&logo=googledrive&logoColor=white)](https://drive.google.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Um container Docker robusto e pronto para produção para backups automatizados de bancos de dados MySQL no Google Drive usando Rclone. Possui tratamento seguro de credenciais, tratamento abrangente de erros, verificações de saúde e agendamento flexível.

## ✨ Funcionalidades

- 🔒 **Seguro**: Arquivo de credenciais temporário previne exposição de senhas
- 🚀 **Automatizado**: Agendamento via cron configurável para operação sem intervenção
- 📊 **Multi-banco**: Backup de múltiplos bancos de dados em uma única execução
- ☁️ **Armazenamento em Nuvem**: Upload direto para o Google Drive via Rclone
- 🧹 **Limpeza Automática**: Retenção configurável de backups locais
- 📝 **Logging Estruturado**: Múltiplos níveis de log com timestamps
- 🔔 **Notificações**: Suporte a webhooks para Slack/Discord/Teams
- 🏥 **Verificações de Saúde**: Monitoramento integrado do container
- 🌍 **Suporte a Fuso Horário**: Configuração adequada de timezone
- 🐳 **Pronto para Docker Swarm**: Deploy em produção com Docker Swarm
- 🧪 **Testado**: Suite de testes abrangente incluída

## 🚀 Início Rápido

### Pré-requisitos

- Docker instalado
- Conta do Google Drive
- Servidor MySQL acessível do container

### 1. Configurar Rclone

```bash
# Criar volume de configuração do rclone
docker volume create rclone_config

# Configurar rclone (siga a configuração interativa)
docker run --rm -it -v rclone_config:/root/.config/rclone rclone/rclone:latest config
```

### 2. Executar com Docker Compose

```bash
# Clonar o repositório
git clone https://github.com/alian87/mysql-backup-rclone.git
cd mysql-backup-rclone

# Copiar e personalizar o exemplo
cp examples/docker-compose.example.yml docker-compose.yml
# Editar docker-compose.yml com suas configurações

# Iniciar o serviço de backup
docker-compose up -d
```

### 3. Deploy com Docker Swarm

```bash
# Copiar e personalizar o arquivo de stack
cp examples/stack.example.yml stack.yml
# Editar stack.yml com suas configurações

# Fazer deploy da stack
docker stack deploy -c stack.yml mysql-backup
```

## 📋 Configuração

### Variáveis de Ambiente

| Variável | Descrição | Padrão | Obrigatório |
|----------|-----------|--------|-------------|
| `MYSQL_HOST` | Hostname do servidor MySQL | `localhost` | Sim |
| `MYSQL_PORT` | Porta do servidor MySQL | `3306` | Não |
| `MYSQL_USER` | Usuário MySQL | `root` | Sim |
| `MYSQL_PASSWORD` | Senha MySQL | - | Sim |
| `MYSQL_DATABASES` | Nomes dos bancos separados por vírgula | - | Sim |
| `RCLONE_REMOTE` | Caminho remoto do Rclone | `gdrive:backups` | Sim |
| `CRON_SCHEDULE` | Expressão cron para agendamento | `0 3 * * *` | Não |
| `BACKUP_RETENTION` | Número de backups locais para manter | `5` | Não |
| `TZ` | Fuso horário | `America/Sao_Paulo` | Não |
| `LOG_LEVEL` | Nível de log (DEBUG/INFO/WARN/ERROR) | `INFO` | Não |
| `WEBHOOK_URL` | URL do webhook para notificações | - | Não |

### Exemplos de Agendamento Cron

```bash
# Diariamente às 2h da manhã
CRON_SCHEDULE="0 2 * * *"

# A cada 6 horas
CRON_SCHEDULE="0 */6 * * *"

# Semanalmente no domingo às 3h da manhã
CRON_SCHEDULE="0 3 * * 0"

# Mensalmente no dia 1 à meia-noite
CRON_SCHEDULE="0 0 1 * *"
```

## 🏗️ Arquitetura

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Cron Job  │ --> │  backup.sh   │ --> │ Google Drive│
│ (agendado)  │     │ (mysqldump)  │     │  (rclone)   │
└─────────────┘     └──────────────┘     └─────────────┘
       │                     │                     │
       v                     v                     v
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Logging   │     │   Cleanup    │     │ Notifications│
│ (estruturado)│     │ (retenção)  │     │  (webhook)  │
└─────────────┘     └──────────────┘     └─────────────┘
```

## 📁 Estrutura do Projeto

```
mysql-backup-rclone/
├── Dockerfile                 # Definição do container
├── docker-compose.yml         # Configuração de desenvolvimento
├── stack.yml                  # Deploy em produção
├── src/
│   ├── backup.sh             # Script principal de backup
│   └── entrypoint.sh         # Inicialização do container
├── examples/
│   ├── docker-compose.example.yml
│   ├── stack.example.yml
│   ├── rclone-setup.md
│   └── mysql-init/
├── tests/
│   ├── test-backup.sh        # Suite de testes
│   └── README.md
├── docs/
└── README.md
```

## 🔧 Exemplos de Uso

### Uso Básico

```bash
docker run -d \
  --name mysql-backup \
  -e MYSQL_HOST=mysql-server \
  -e MYSQL_USER=backup_user \
  -e MYSQL_PASSWORD=senha_segura \
  -e MYSQL_DATABASES=db1,db2,db3 \
  -e RCLONE_REMOTE=gdrive:backups/mysql \
  -v rclone_config:/root/.config/rclone \
  alian87/mysql-backup-rclone:latest
```

### Com Notificações

```bash
docker run -d \
  --name mysql-backup \
  -e MYSQL_HOST=mysql-server \
  -e MYSQL_USER=backup_user \
  -e MYSQL_PASSWORD=senha_segura \
  -e MYSQL_DATABASES=banco_producao \
  -e RCLONE_REMOTE=gdrive:backups/mysql \
  -e WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -e CRON_SCHEDULE="0 2 * * *" \
  -v rclone_config:/root/.config/rclone \
  alian87/mysql-backup-rclone:latest
```

### Backup Manual

```bash
# Executar backup manualmente
docker exec mysql-backup /scripts/backup.sh

# Ver logs
docker logs mysql-backup

# Acompanhar logs em tempo real
docker logs -f mysql-backup
```

## 🧪 Testes

### Executar Suite de Testes

```bash
# Executar testes abrangentes
./tests/test-backup.sh --build --cleanup

# Executar testes com saída verbosa
./tests/test-backup.sh --verbose

# Executar testes e manter containers para inspeção
./tests/test-backup.sh --build
```

### Testes Manuais

```bash
# Construir a imagem
docker build -t mysql-backup-rclone .

# Testar com container MySQL de exemplo
docker-compose up -d mysql
sleep 30
docker-compose up backup
```

## 📊 Monitoramento

### Verificações de Saúde

O container inclui verificações de saúde integradas:

```bash
# Verificar saúde do container
docker ps

# Ver logs de verificação de saúde
docker inspect mysql-backup | jq '.[0].State.Health'
```

### Logging

Logging estruturado com múltiplos níveis:

```bash
# Ver todos os logs
docker logs mysql-backup

# Ver apenas logs de erro
docker logs mysql-backup 2>&1 | grep ERROR

# Ver resumos de backup
docker logs mysql-backup 2>&1 | grep "Backup Summary"
```

### Métricas

O container fornece métricas básicas através dos logs:

- Taxas de sucesso/falha do backup
- Tamanhos dos bancos de dados
- Tempos de upload
- Estatísticas de limpeza

## 🔒 Segurança

### Melhores Práticas

1. **Use Docker Secrets** para dados sensíveis em produção
2. **Restrinja acesso de rede** ao servidor MySQL
3. **Use usuário dedicado para backup** com privilégios mínimos
4. **Rotacione regularmente** as credenciais da API do Google Drive
5. **Monitore logs de backup** para atividade suspeita

### Exemplo de Docker Secrets

```yaml
# docker-compose.yml
version: '3.8'
services:
  mysql-backup:
    image: alian87/mysql-backup-rclone:latest
    secrets:
      - mysql_password
    environment:
      MYSQL_PASSWORD_FILE: /run/secrets/mysql_password

secrets:
  mysql_password:
    external: true
```

### Permissões do Usuário de Backup

```sql
-- Criar usuário dedicado para backup
CREATE USER 'backup_user'@'%' IDENTIFIED BY 'senha_segura';

-- Conceder permissões mínimas necessárias
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup_user'@'%';
FLUSH PRIVILEGES;
```

## 🚨 Solução de Problemas

### Problemas Comuns

#### Container não inicia
```bash
# Verificar logs
docker logs mysql-backup

# Causas comuns:
# - Configuração do rclone ausente
# - Variáveis de ambiente inválidas
# - Problemas de conectividade de rede
```

#### Falhas de backup
```bash
# Verificar conectividade MySQL
docker exec mysql-backup mysql -h mysql-server -u user -p -e "SELECT 1"

# Verificar configuração do rclone
docker exec mysql-backup rclone lsd gdrive:

# Habilitar logging de debug
docker run -e LOG_LEVEL=DEBUG ... mysql-backup-rclone
```

#### Falhas de upload
```bash
# Testar conexão do rclone
docker exec mysql-backup rclone about gdrive:

# Verificar cota do Google Drive
docker exec mysql-backup rclone about gdrive: | grep Used
```

### Modo Debug

Habilitar logging de debug para troubleshooting detalhado:

```bash
docker run -e LOG_LEVEL=DEBUG ... mysql-backup-rclone
```

## 📈 Performance

### Dicas de Otimização

1. **Use `--single-transaction`** para tabelas InnoDB (já incluído)
2. **Ajuste `--quick`** para tabelas grandes (já incluído)
3. **Otimize configurações do rclone** para uploads grandes
4. **Use armazenamento SSD** para diretório de backup
5. **Monitore uso de recursos** durante backups

### Requisitos de Recursos

| Componente | CPU | RAM | Disco |
|------------|-----|-----|-------|
| Container | 0.25-0.5 cores | 256-512MB | 50MB |
| Backup Local | - | - | 5x tamanho do banco |
| Google Drive | - | - | Ilimitado* |

*Depende do plano do Google Workspace

## 🤝 Contribuindo

1. Faça um fork do repositório
2. Crie uma branch de feature (`git checkout -b feature/feature-incrivel`)
3. Commit suas mudanças (`git commit -m 'Adicionar feature incrível'`)
4. Push para a branch (`git push origin feature/feature-incrivel`)
5. Abra um Pull Request

### Configuração de Desenvolvimento

```bash
# Clonar o repositório
git clone https://github.com/alian87/mysql-backup-rclone.git
cd mysql-backup-rclone

# Construir a imagem
docker build -t mysql-backup-rclone .

# Executar testes
./tests/test-backup.sh --build --cleanup
```

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

- [Rclone](https://rclone.org/) para sincronização de armazenamento em nuvem
- [MySQL](https://www.mysql.com/) para o sistema de banco de dados
- [Docker](https://www.docker.com/) para containerização
- [Google Drive](https://drive.google.com/) para armazenamento em nuvem

## 📞 Suporte

- 📖 [Documentação](docs/)
- 🐛 [Rastreador de Issues](https://github.com/alian87/mysql-backup-rclone/issues)
- 💬 [Discussões](https://github.com/alian87/mysql-backup-rclone/discussions)
- 📧 [Email](mailto:alian87@example.com)

---

**⭐ Se este projeto te ajuda, por favor dê uma estrela!**
