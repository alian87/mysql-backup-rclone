# 🚀 Instruções para Atualização no GitHub

## 📋 Resumo das Mudanças (v1.0.0 → v2.0.9)

Esta é uma atualização maior com várias correções críticas e melhorias de compatibilidade.

### 🔴 Mudanças Críticas (Breaking Changes)

**v2.0.0**: 
- Mudança de base image de `debian:bookworm-slim` para `ubuntu:18.04`
- Necessário para compatibilidade com MySQL 5.5+
- MariaDB client rebaixado de 10.11 para 10.1

### ✅ Principais Correções

1. **v2.0.9** - Cron não executava automaticamente
   - Mudou de `/etc/cron.d/` para `crontab` direto
   - Adicionado wrapper script para variáveis de ambiente

2. **v2.0.8** - Limpeza de backups remotos
   - Agora limpa backups antigos no Google Drive
   - Respeita `BACKUP_RETENTION` para local e remoto

3. **v2.0.7** - Timezone nos logs
   - Timestamps agora mostram timezone correto

4. **v2.0.6** - Configuração de timezone
   - Timezone do sistema agora funciona corretamente

5. **v2.0.5** - Race conditions
   - Implementado lock file para prevenir backups concorrentes
   - Arquivos temporários únicos por processo

6. **v2.0.0** - Compatibilidade MySQL 5.5
   - Corrigido erros `generation_expression`
   - Melhor compatibilidade com MySQL antigo

---

## 📝 Comandos Git para Atualização

Execute estes comandos **na ordem**:

```bash
# 1. Navegar até o diretório do projeto
cd D:\OneDrive\Desktop\backup_drive\mysql-backup-rclone

# 2. Verificar status atual
git status

# 3. Adicionar todos os arquivos modificados
git add .

# 4. Fazer commit com mensagem descritiva
git commit -m "Release v2.0.9: Critical fixes and improvements

Major Changes:
- Fixed cron not executing automatically (CRITICAL)
- Added automatic remote backup cleanup on Google Drive
- Fixed timezone display in logs
- Fixed race conditions in concurrent executions
- Changed base image to Ubuntu 18.04 for MySQL 5.5+ compatibility

Breaking Changes:
- Base image changed from Debian Bookworm to Ubuntu 18.04
- MariaDB client version downgraded to 10.1 for compatibility

For full changelog, see CHANGELOG.md"

# 5. Criar tag para a versão
git tag -a v2.0.9 -m "Release v2.0.9

Critical fixes:
- Cron job now executes automatically
- Remote backup cleanup added
- Timezone corrections
- Race condition fixes
- MySQL 5.5+ compatibility"

# 6. Push para o repositório remoto
git push origin main

# 7. Push das tags
git push origin --tags

# 8. (Opcional) Criar release no GitHub
# Acesse: https://github.com/SEU_USUARIO/mysql-backup-rclone/releases/new
# - Tag: v2.0.9
# - Title: Release v2.0.9 - Critical Fixes & MySQL 5.5 Compatibility
# - Description: Use o conteúdo do CHANGELOG.md para v2.0.9
```

---

## 🐳 Docker Hub

As imagens já foram publicadas:
- `alian87/mysql-backup-rclone:2.0.9`
- `alian87/mysql-backup-rclone:latest`

---

## 📄 Arquivos Atualizados

### Documentação:
- ✅ `CHANGELOG.md` - Adicionadas versões 2.0.0 até 2.0.9
- ✅ `CHANGELOG-pt.md` - Adicionadas versões 2.0.0 até 2.0.9

### Código:
- ✅ `Dockerfile` - v2.0.9, base image Ubuntu 18.04
- ✅ `src/backup.sh` - v2.0.9, lock file, cleanup remoto
- ✅ `src/entrypoint.sh` - v2.0.9, crontab fix

### Configuração:
- ✅ `.gitattributes` - Line endings LF para .sh

---

## 🔍 Checklist Antes do Push

- [ ] Todos os scripts `.sh` têm line endings LF (não CRLF)
- [ ] CHANGELOG.md atualizado com todas as versões
- [ ] CHANGELOG-pt.md atualizado com todas as versões
- [ ] Versões nos arquivos coincidem (Dockerfile, backup.sh, entrypoint.sh)
- [ ] Imagens Docker publicadas no Docker Hub
- [ ] Testes manuais executados e funcionando

---

## 📦 Release Notes (Para GitHub)

### Título:
```
Release v2.0.9 - Critical Fixes & MySQL 5.5 Compatibility
```

### Descrição:
```markdown
## 🚨 Critical Fixes

This release fixes several critical issues and adds important improvements.

### Fixed
- **CRITICAL**: Cron job not executing automatically in containers
  - Changed from `/etc/cron.d/` to `crontab` for better reliability
  - Added wrapper script for proper environment variable handling
- **NEW**: Automatic cleanup of remote backups on Google Drive
- Fixed timezone display in logs
- Fixed race conditions in concurrent backup executions
- Fixed compatibility with MySQL 5.5+ servers

### Breaking Changes
⚠️ Base image changed from Debian Bookworm to Ubuntu 18.04
- This provides better compatibility with older MySQL servers (5.5+)
- MariaDB client downgraded to 10.1

### Upgrade Instructions
1. Pull the new image: `docker pull alian87/mysql-backup-rclone:latest`
2. Update your service: `docker service update --image alian87/mysql-backup-rclone:latest your-service`
3. Verify cron is working: `docker service logs -f your-service`

### Full Changelog
See [CHANGELOG.md](CHANGELOG.md) for complete version history.

### Docker Images
- `alian87/mysql-backup-rclone:2.0.9`
- `alian87/mysql-backup-rclone:latest`
```

---

## 🎯 Próximos Passos

1. Execute os comandos git acima
2. Verifique se o push foi bem-sucedido
3. Crie um release no GitHub com as release notes
4. (Opcional) Atualize a descrição no Docker Hub

---

## ⚠️ Notas Importantes

- **Line Endings**: Certifique-se que `.gitattributes` está commitado para garantir line endings corretos
- **Tags**: As tags seguem Semantic Versioning (MAJOR.MINOR.PATCH)
- **Docker Hub**: As imagens já foram publicadas e testadas
- **Compatibilidade**: v2.0.x requer MySQL 5.5 ou superior

---

**Data de Criação**: 2025-10-08  
**Versão Atual**: 2.0.9  
**Status**: ✅ Pronto para Deploy

