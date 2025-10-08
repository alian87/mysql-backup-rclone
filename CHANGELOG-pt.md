# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não Lançado]

## [2.0.9] - 2025-10-08

### Corrigido
- **Crítico**: Corrigido cron job não executando automaticamente em containers
- Mudado de `/etc/cron.d/` para `crontab` para melhor compatibilidade com containers
- Adicionado script wrapper para carregar variáveis de ambiente corretamente no contexto do cron
- Adicionado log de debug para mostrar conteúdo do crontab instalado

### Alterado
- Melhorada confiabilidade do cron em containers Docker
- Melhor tratamento de variáveis de ambiente para tarefas agendadas

## [2.0.8] - 2025-10-08

### Adicionado
- **Limpeza automática de backups remotos** no Google Drive
- Agora remove backups antigos do armazenamento remoto (não apenas local)
- Respeita configuração `BACKUP_RETENTION` para limpeza local e remota

### Alterado
- Rebuild completo sem cache para garantir build limpo
- Separada limpeza de backup local e remoto nos logs

## [2.0.7] - 2025-10-08

### Corrigido
- **Exibição de timezone nos logs** agora mostra corretamente horário local ao invés de UTC
- Timestamps dos logs agora respeitam variável de ambiente `TZ`

### Alterado
- Modificada função `log()` para usar explicitamente a timezone configurada

## [2.0.6] - 2025-10-08

### Corrigido
- **Configuração de timezone** agora funciona corretamente
- Adicionado pacote `tzdata` e configuração adequada de timezone
- Adicionado `dpkg-reconfigure` para configuração de timezone

### Alterado
- Movida configuração de timezone para depois da instalação de pacotes
- Adicionado `DEBIAN_FRONTEND=noninteractive` para prevenir prompts

## [2.0.5] - 2025-10-08

### Corrigido
- Race condition quando múltiplos jobs de backup executam simultaneamente
- Conflitos de arquivo de configuração MySQL entre execuções concorrentes

### Adicionado
- **Mecanismo de lock file** (`/var/run/backup.lock`) para prevenir backups concorrentes
- Arquivos temporários de configuração MySQL únicos por processo (`/tmp/mysql_$$.cnf`)
- Detecção e limpeza de locks obsoletos
- Logging de aquisição e liberação de lock

### Segurança
- Melhorada segurança de execução concorrente
- Melhor limpeza de arquivos temporários

## [2.0.0] - 2025-10-08

### Alterado
- **BREAKING**: Mudada imagem base de `debian:bookworm-slim` para `ubuntu:18.04`
- Esta mudança fornece melhor compatibilidade com servidores MySQL antigos (5.5+)
- Versão do cliente MariaDB rebaixada para 10.1 para compatibilidade

### Corrigido
- Corrigido erros `generation_expression` com servidores MySQL 5.5 antigos
- Melhorada compatibilidade do mysqldump entre diferentes versões do MySQL
- Melhor tratamento de erros para falhas do mysqldump

### Adicionado
- Adicionado pacote `bc` para cálculos numéricos
- Logging aprimorado com mensagens de nível DEBUG
- Melhor rastreamento do processamento de backup de bancos de dados

### Técnico
- Simplificadas flags do mysqldump para melhor compatibilidade
- Removido `set -e` durante loop de backup para tratar erros não críticos
- Adicionado fallback para `numfmt` quando não disponível

## [1.0.0] - 2025-01-07

### Adicionado
- Lançamento inicial do MySQL Backup com Rclone
- Backup automatizado de bancos de dados MySQL para Google Drive
- Suporte para múltiplos bancos de dados
- Agendamento via cron configurável
- Limpeza automática de backups antigos
- Verificações de saúde para monitoramento do container
- Logging estruturado com diferentes níveis
- Suporte a notificações via webhook
- Suporte para Docker Compose e Docker Swarm
- Tratamento abrangente de erros e validação
- Melhorias de segurança (arquivo de credenciais temporário)
- Suporte a configuração de fuso horário
- Limites de recursos e restrições
- Documentação abrangente e exemplos

### Segurança
- Corrigido exposição de senha na lista de processos
- Implementado arquivo de credenciais MySQL temporário
- Adicionadas permissões adequadas de arquivo (600) para arquivos sensíveis
- Melhorado tratamento de erros para prevenir vazamento de informações

### Funcionalidades
- Suporte para múltiplos bancos de dados MySQL
- Retenção de backup configurável
- Relatórios de progresso durante uploads
- Resumos detalhados de backup
- Teste de conectividade antes do backup
- Tratamento gracioso de erros e recuperação
- Suporte para MySQL 5.7 e 8.0
- Compatível com Docker Swarm e Docker Compose

### Documentação
- README completo com exemplos de uso
- Guia de solução de problemas
- Referência de configuração
- Instruções de deploy
- Melhores práticas de segurança
- Dicas de otimização de performance
