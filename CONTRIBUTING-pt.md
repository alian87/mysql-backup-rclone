# Contribuindo para MySQL Backup Rclone

Obrigado pelo seu interesse em contribuir para o MySQL Backup Rclone! Este documento fornece diretrizes e informações para contribuidores.

## 🚀 Começando

### Pré-requisitos

- Docker instalado e executando
- Git configurado com suas credenciais
- Conhecimento básico de shell scripting
- Compreensão de conceitos MySQL e Docker

### Configuração de Desenvolvimento

1. **Fazer fork do repositório**
   ```bash
   # Fazer fork no GitHub, depois clonar seu fork
   git clone https://github.com/yourusername/mysql-backup-rclone.git
   cd mysql-backup-rclone
   ```

2. **Configurar ambiente de desenvolvimento**
   ```bash
   # Construir imagem de desenvolvimento
   docker build -t mysql-backup-rclone:dev .
   
   # Executar testes para garantir que tudo funciona
   ./tests/test-backup.sh --build --cleanup
   ```

3. **Criar branch de feature**
   ```bash
   git checkout -b feature/nome-da-sua-feature
   ```

## 📋 Diretrizes de Contribuição

### Estilo de Código

- **Scripts Shell**: Seguir [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Comentários**: Usar comentários claros e descritivos
- **Funções**: Manter funções pequenas e focadas
- **Tratamento de Erros**: Sempre usar `set -euo pipefail`
- **Logging**: Usar logging estruturado com timestamps

### Mensagens de Commit

Seguir formato [Conventional Commits](https://www.conventionalcommits.org/):

```
tipo(escopo): descrição

[corpo opcional]

[rodapé opcional]
```

Exemplos:
```
feat(backup): adicionar suporte para bancos PostgreSQL
fix(entrypoint): resolver problema de configuração de timezone
docs(readme): atualizar instruções de instalação
test(backup): adicionar testes de integração para bancos grandes
```

### Processo de Pull Request

1. **Atualizar documentação** para novas features
2. **Adicionar testes** para nova funcionalidade
3. **Garantir que todos os testes passem**
4. **Atualizar CHANGELOG.md** com suas mudanças
5. **Criar PR descritivo** com:
   - Título e descrição claros
   - Link para issues relacionadas
   - Screenshots (se aplicável)
   - Instruções de teste

## 🧪 Testes

### Executando Testes

```bash
# Executar suite completa de testes
./tests/test-backup.sh --build --cleanup

# Executar testes com saída verbosa
./tests/test-backup.sh --verbose

# Executar testes sem limpeza (para debug)
./tests/test-backup.sh --build
```

### Escrevendo Testes

Ao adicionar novas features, incluir testes em `tests/test-backup.sh`:

```bash
# Adicionar função de teste
test_nova_feature() {
    log_info "Testando nova feature..."
    
    # Implementação do teste
    if docker exec "$CONTAINER_NAME" comando_teste_nova_feature; then
        log_success "Teste da nova feature passou"
    else
        log_error "Teste da nova feature falhou"
        return 1
    fi
}

# Chamar teste na função principal
test_nova_feature
```

### Testes Manuais

```bash
# Testar com diferentes configurações
docker run --rm -e MYSQL_DATABASES="testdb" ... mysql-backup-rclone:dev

# Testar condições de erro
docker run --rm -e MYSQL_HOST="invalido" ... mysql-backup-rclone:dev
```

## 🏗️ Diretrizes de Arquitetura

### Adicionando Novas Features

1. **Variáveis de Ambiente**: Adicionar ao Dockerfile e documentar no README
2. **Configuração**: Usar variáveis de ambiente, não arquivos de config
3. **Logging**: Usar funções de logging existentes
4. **Tratamento de Erros**: Seguir padrões existentes
5. **Segurança**: Nunca expor dados sensíveis nos logs

### Estrutura de Script

```bash
#!/bin/bash
set -euo pipefail

# Configuração
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Função de logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a /var/log/cron.log
}

# Função principal
main() {
    log "INFO" "Iniciando feature..."
    
    # Implementação
    
    log "INFO" "Feature concluída"
}

# Executar função principal
main "$@"
```

## 📚 Documentação

### Atualizando Documentação

- **README.md**: Atualizar para novas features, opções de configuração
- **CHANGELOG.md**: Adicionar entradas para todas as mudanças
- **TROUBLESHOOTING.md**: Adicionar problemas comuns e soluções
- **Exemplos**: Atualizar arquivos de exemplo com novas opções

### Padrões de Documentação

- Usar linguagem clara e concisa
- Incluir exemplos de código
- Fornecer informações de troubleshooting
- Manter exemplos atualizados com últimas features

## 🐛 Relatórios de Bug

### Antes de Reportar

1. **Verificar issues existentes** para evitar duplicatas
2. **Atualizar para versão mais recente** para garantir que bug não foi corrigido
3. **Habilitar logging de debug** para coletar mais informações
4. **Testar com configuração mínima** para isolar o problema

### Template de Relatório de Bug

```markdown
**Descrever o bug**
Uma descrição clara do que é o bug.

**Para Reproduzir**
Passos para reproduzir o comportamento:
1. Definir variáveis de ambiente para '...'
2. Executar comando '...'
3. Ver erro

**Comportamento Esperado**
O que você esperava que acontecesse.

**Comportamento Atual**
O que realmente aconteceu.

**Ambiente:**
- Versão do Docker: [ex: 20.10.12]
- Versão da imagem: [ex: 1.0.0]
- Versão do MySQL: [ex: 8.0.28]
- SO: [ex: Ubuntu 20.04]

**Configuração:**
```yaml
# docker-compose.yml ou variáveis de ambiente
```

**Logs:**
```
# Saída de log relevante
```

**Contexto Adicional**
Qualquer outro contexto sobre o problema.
```

## 💡 Solicitações de Feature

### Antes de Solicitar

1. **Verificar issues existentes** para solicitações similares
2. **Considerar o escopo** - está dentro dos objetivos do projeto?
3. **Pensar na implementação** - é viável?
4. **Considerar alternativas** - features existentes podem ser estendidas?

### Template de Solicitação de Feature

```markdown
**Sua solicitação de feature está relacionada a um problema?**
Uma descrição clara do que é o problema.

**Descrever a solução que você gostaria**
Uma descrição clara do que você quer que aconteça.

**Descrever alternativas que você considerou**
Uma descrição clara de soluções alternativas.

**Caso de uso**
Por que esta feature é necessária? Que problema ela resolve?

**Ideias de implementação**
Alguma ideia de como isso poderia ser implementado?
```

## 🔒 Segurança

### Diretrizes de Segurança

- **Nunca commitar segredos** (senhas, chaves de API, etc.)
- **Usar variáveis de ambiente** para configuração
- **Validar entrada** para prevenir ataques de injeção
- **Seguir princípio do menor privilégio**
- **Reportar problemas de segurança** privadamente

### Reportando Problemas de Segurança

Enviar problemas de segurança para: security@example.com

Não criar issues públicas para vulnerabilidades de segurança.

## 📊 Performance

### Considerações de Performance

- **Minimizar tamanho do container** usando builds multi-stage
- **Otimizar scripts de backup** para bancos grandes
- **Usar algoritmos eficientes** para operações de limpeza
- **Monitorar uso de recursos** durante desenvolvimento

### Benchmarking

```bash
# Testar performance de backup
time docker exec mysql-backup /scripts/backup.sh

# Monitorar uso de recursos
docker stats mysql-backup

# Testar com bancos grandes
docker run -e MYSQL_DATABASES="banco_grande" ... mysql-backup-rclone
```

## 🎯 Objetivos do Projeto

### Áreas de Foco Atuais

1. **Confiabilidade**: Melhorar tratamento de erros e recuperação
2. **Performance**: Otimizar para bancos grandes
3. **Segurança**: Melhorar tratamento de credenciais
4. **Monitoramento**: Adicionar melhor observabilidade
5. **Documentação**: Melhorar experiência do usuário

### Considerações Futuras

- Suporte para outros bancos (PostgreSQL, MongoDB)
- Criptografia de backup
- Backups incrementais
- Suporte multi-cloud
- Deploy Kubernetes

## 📞 Obtendo Ajuda

### Canais de Comunicação

- **GitHub Issues**: Relatórios de bug e solicitações de feature
- **GitHub Discussions**: Perguntas e discussão geral
- **Email**: Contato direto para issues sensíveis

### Processo de Revisão de Código

1. **Verificações automatizadas** devem passar
2. **Pelo menos um revisor** necessário
3. **Todo feedback endereçado** antes do merge
4. **Testes devem passar** em todas as plataformas
5. **Documentação atualizada** conforme necessário

## 🙏 Reconhecimento

Contribuidores serão reconhecidos em:
- **README.md** seção de contribuidores
- **CHANGELOG.md** para contribuições significativas
- **Notas de release** para features principais

Obrigado por contribuir para o MySQL Backup Rclone! 🎉
