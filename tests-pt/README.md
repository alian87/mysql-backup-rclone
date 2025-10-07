# Suite de Testes

Este diretório contém testes para o projeto MySQL Backup Rclone.

## Scripts de Teste

### test-backup.sh

Script de teste abrangente que valida a funcionalidade de backup em um ambiente controlado.

#### Uso

```bash
# Executar testes com construção da imagem
./tests/test-backup.sh --build --cleanup

# Executar testes com saída verbosa
./tests/test-backup.sh --verbose

# Executar testes e manter containers para inspeção
./tests/test-backup.sh --build
```

#### Opções

- `--build`: Construir a imagem Docker antes dos testes
- `--cleanup`: Limpar recursos de teste após os testes
- `--verbose`: Habilitar saída verbosa

#### O que testa

1. **Inicialização do container**: Verifica se o container inicia com sucesso
2. **Conectividade MySQL**: Testa conexão com servidor MySQL
3. **Backup manual**: Executa script de backup manualmente
4. **Criação de arquivos de backup**: Verifica se arquivos de backup são criados
5. **Job cron**: Testa execução de backup agendado
6. **Verificação de saúde**: Valida funcionalidade de health check
7. **Logging**: Verifica criação e conteúdo do arquivo de log

#### Pré-requisitos

- Docker instalado e executando
- Conexão com internet (para baixar imagens base)
- Espaço em disco suficiente para containers de teste

#### Ambiente de Teste

O script de teste cria:
- Um container MySQL de teste com dados de exemplo
- Um container de backup de teste
- Uma rede Docker de teste
- Um volume Docker de teste para configuração do rclone

#### Saída de Exemplo

```
[INFO] Construindo imagem Docker...
[SUCCESS] Imagem construída com sucesso
[INFO] Criando rede de teste...
[INFO] Criando volume de teste...
[INFO] Iniciando container MySQL de teste...
[INFO] Aguardando MySQL ficar pronto...
[SUCCESS] MySQL está pronto
[INFO] Criando bancos de dados e dados de teste...
[INFO] Criando configuração de teste do rclone...
[INFO] Iniciando container de backup...
[INFO] Aguardando container de backup iniciar...
[SUCCESS] Container de backup está executando
[INFO] Testando execução manual de backup...
[SUCCESS] Teste de backup manual passou
[INFO] Verificando arquivos de backup...
[SUCCESS] Arquivos de backup encontrados
[INFO] Testando job cron...
[INFO] Verificando logs do cron...
[SUCCESS] Teste de job cron passou
[INFO] Testando verificação de saúde...
[SUCCESS] Verificação de saúde passou
[SUCCESS] Todos os testes passaram! 🎉
```

## Testes Manuais

### Teste Rápido

```bash
# Construir a imagem
docker build -t mysql-backup-rclone .

# Executar um teste rápido
docker run --rm \
  -e MYSQL_HOST=seu-host-mysql \
  -e MYSQL_USER=seu-usuario \
  -e MYSQL_PASSWORD=sua-senha \
  -e MYSQL_DATABASES=testdb \
  -e RCLONE_REMOTE=gdrive:test \
  -v rclone_config:/root/.config/rclone \
  mysql-backup-rclone /scripts/backup.sh
```

### Teste de Integração

```bash
# Iniciar container MySQL
docker run -d --name mysql-test \
  -e MYSQL_ROOT_PASSWORD=testpass \
  -e MYSQL_DATABASE=testdb \
  mysql:8.0

# Aguardar MySQL iniciar
sleep 30

# Executar container de backup
docker run --rm --link mysql-test:mysql \
  -e MYSQL_HOST=mysql \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=testpass \
  -e MYSQL_DATABASES=testdb \
  -e RCLONE_REMOTE=gdrive:test \
  -v rclone_config:/root/.config/rclone \
  mysql-backup-rclone /scripts/backup.sh

# Limpeza
docker stop mysql-test
docker rm mysql-test
```

## Solução de Problemas

### Problemas Comuns

1. **Falha na conexão MySQL**: Verificar se container MySQL está executando e acessível
2. **Configuração do Rclone não encontrada**: Garantir que volume do rclone está montado corretamente
3. **Permissão negada**: Verificar permissões de arquivo nos scripts
4. **Problemas de rede**: Verificar conectividade da rede Docker

### Modo Debug

Habilitar logging de debug definindo `LOG_LEVEL=DEBUG`:

```bash
docker run -e LOG_LEVEL=DEBUG ... mysql-backup-rclone
```

### Ver Logs

```bash
# Ver logs do container
docker logs nome-do-container

# Acompanhar logs em tempo real
docker logs -f nome-do-container

# Ver logs do cron dentro do container
docker exec nome-do-container cat /var/log/cron.log
```

## Integração Contínua

Para pipelines CI/CD, use o script de teste com limpeza:

```bash
./tests/test-backup.sh --build --cleanup --verbose
```

Isso garante um ambiente de teste limpo e limpeza adequada após os testes.
