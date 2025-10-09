# 🧪 Guia de Testes - Versão 2.1.0

## 📋 O que foi corrigido

A versão **2.1.0** corrige um bug crítico onde os backups locais **não estavam sendo removidos** do diretório `/backup` no container, mesmo com a configuração `BACKUP_RETENTION`.

### 🐛 Problema Anterior
O comando `find | sort -z | head -n -N` estava falhando porque o `head` não suporta entrada null-terminated (`-z`).

### ✅ Solução
Substituído por um array bash usando `mapfile`, que é mais robusto e confiável.

---

## 🔄 Como Atualizar Seu Container

### 1️⃣ Atualizar a Stack

```bash
# Editar sua stack para usar a nova versão
vi /path/to/stack.yml
```

Altere a linha da imagem para:
```yaml
image: alian87/mysql-backup-rclone:2.1.0
```

Ou use `latest` (já aponta para 2.1.0):
```yaml
image: alian87/mysql-backup-rclone:latest
```

### 2️⃣ Atualizar o Serviço

```bash
# Atualizar o serviço com a nova imagem
docker service update --image alian87/mysql-backup-rclone:2.1.0 mysql-backup_mysql-backup

# Ou forçar recreação completa
docker stack rm mysql-backup
docker stack deploy -c /path/to/stack.yml mysql-backup
```

### 3️⃣ Verificar Atualização

```bash
# Ver se a versão está correta
docker exec $(docker ps -q -f name=mysql-backup_mysql-backup) bash -c "grep 'Version:' /scripts/backup.sh"
```

Deve mostrar: `# Version: 2.1.0`

---

## ✅ Testes de Validação

### Teste 1: Verificar Limpeza Local Está Funcionando

```bash
# 1. Entrar no container
docker exec -it $(docker ps -q -f name=mysql-backup_mysql-backup) bash

# 2. Ver quantos backups existem
ls -lt /backup/ | grep '^d' | wc -l

# 3. Simular comando de limpeza (sem deletar)
retention=48
echo "=== Backups que SERÃO MANTIDOS (últimos $retention) ==="
find /backup -maxdepth 1 -type d -name "20*" | sort | tail -n $retention

echo ""
echo "=== Backups que SERÃO DELETADOS ==="
find /backup -maxdepth 1 -type d -name "20*" | sort | head -n -$retention
```

### Teste 2: Forçar um Backup Manual e Ver Limpeza

```bash
# Dentro do container:
LOG_LEVEL=DEBUG /scripts/backup.sh
```

Você deve ver logs como:
```
[INFO] 🧹 Cleaning up old local backups (keeping last 48)...
[DEBUG] Removed old local backup: 2025-10-08_18-00-00
[DEBUG] Removed old local backup: 2025-10-08_18-30-00
[INFO] 🧹 Cleaned up 2 old local backup(s)
```

### Teste 3: Verificar Contagem Antes e Depois

```bash
# Contar backups ANTES
echo "Backups antes: $(find /backup -maxdepth 1 -type d -name "20*" | wc -l)"

# Executar backup
/scripts/backup.sh

# Contar backups DEPOIS
echo "Backups depois: $(find /backup -maxdepth 1 -type d -name "20*" | wc -l)"
```

**Resultado esperado**: Se tiver mais de 48 backups, após o script a contagem deve ser 48.

---

## 🎯 Cenários de Teste

### Cenário 1: Container Novo (poucos backups)
- **Situação**: Menos de 48 backups no `/backup`
- **Resultado esperado**: Nenhum backup deletado
- **Teste**:
  ```bash
  ls -lt /backup/ | grep '^d' | wc -l
  # Se mostrar < 48, nenhum será deletado
  ```

### Cenário 2: Container com Muitos Backups
- **Situação**: Mais de 48 backups (ex: 100 backups)
- **Resultado esperado**: Manter apenas os 48 mais recentes
- **Teste**:
  ```bash
  # Antes: 100 backups
  # Depois: 48 backups
  ```

### Cenário 3: Backup a cada 30 minutos (24h = 48 backups)
- **Situação**: Seu caso atual
- **Resultado esperado**: Depois de 24h, manter sempre 48 backups
- **Teste**:
  ```bash
  # Aguardar 25-26 horas e verificar:
  find /backup -maxdepth 1 -type d -name "20*" | wc -l
  # Deve ser sempre 48
  ```

---

## 🔍 Troubleshooting

### Problema: Ainda vejo muitos backups locais

**Diagnóstico**:
```bash
docker exec $(docker ps -q -f name=mysql-backup_mysql-backup) bash -c '
retention=48
total=$(find /backup -maxdepth 1 -type d -name "20*" | wc -l)
echo "Total de backups: $total"
echo "Retenção configurada: $retention"
echo ""
if [ $total -gt $retention ]; then
    echo "❌ ERRO: Deveria ter apenas $retention backups!"
    echo "Verificar versão do script:"
    grep "Version:" /scripts/backup.sh
else
    echo "✅ OK: Limpeza funcionando corretamente"
fi
'
```

### Problema: Erro ao executar limpeza

**Diagnóstico**:
```bash
# Testar o comando específico da limpeza
docker exec $(docker ps -q -f name=mysql-backup_mysql-backup) bash -c '
BACKUP_DIR=/backup
retention=48
mapfile -t old_backups < <(find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" | sort | head -n -$retention)
echo "Total de backups a deletar: ${#old_backups[@]}"
for dir in "${old_backups[@]}"; do
    echo "  - $(basename "$dir")"
done
'
```

---

## 📊 Checklist de Validação

Marque conforme for testando:

- [ ] Container atualizado para versão 2.1.0
- [ ] Verificar versão com `grep "Version:" /scripts/backup.sh`
- [ ] Executar backup manual com sucesso
- [ ] Ver logs de limpeza local
- [ ] Confirmar que backups antigos foram removidos
- [ ] Verificar que apenas os últimos 48 backups permanecem
- [ ] Confirmar upload para Google Drive funcionando
- [ ] Confirmar limpeza remota no Drive funcionando

---

## 📞 Suporte

Se continuar com problemas:

1. **Verificar versão**:
   ```bash
   docker exec $(docker ps -q -f name=mysql-backup_mysql-backup) grep "Version:" /scripts/backup.sh
   ```

2. **Ver logs completos**:
   ```bash
   docker service logs -f mysql-backup_mysql-backup
   ```

3. **Executar com DEBUG**:
   ```bash
   docker exec $(docker ps -q -f name=mysql-backup_mysql-backup) bash -c "LOG_LEVEL=DEBUG /scripts/backup.sh"
   ```

---

## ✅ Resultado Esperado Final

Após executar backups por 25-26 horas (com backup a cada 30min):

```bash
# No container:
ls -lt /backup/ | grep '^d' | wc -l
```

**Saída esperada**: `48`

```bash
# Ver os mais antigos:
ls -lt /backup/ | grep '^d' | tail -3
```

Deve mostrar backups de aproximadamente 24 horas atrás.

---

**Versão do Documento**: 2.1.0  
**Data**: 09/10/2025  
**Autor**: Alian

