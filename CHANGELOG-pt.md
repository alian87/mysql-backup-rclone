# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não Lançado]

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
