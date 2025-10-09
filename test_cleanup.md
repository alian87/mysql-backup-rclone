# 🧪 Comandos para Testar Limpeza de Backups

## 🔍 Diagnóstico do Problema

Execute estes comandos **dentro do container** para diagnosticar:

### 1️⃣ Ver quantos backups locais existem

```bash
docker exec $(docker ps -q -f name=mysql-backup_mysql-backup) bash -c "ls -lt /backup/ | grep '^d'"
```

Ou diretamente no container:
```bash
ls -lt /backup/ | grep '^d'
```

### 2️⃣ Ver qual seria o resultado do comando find (sem deletar)

```bash
docker exec $(docker ps -q -f name=mysql-backup_mysql-backup) bash -c "
export BACKUP_RETENTION=7
find /backup -maxdepth 1 -type d -name '20*' -print0 | sort -z | head -z -n -\$BACKUP_RETENTION | xargs -0 -r ls -ld
"
```

Ou diretamente no container:
```bash
export BACKUP_RETENTION=7
find /backup -maxdepth 1 -type d -name '20*' -print0 | sort -z | head -z -n -$BACKUP_RETENTION | xargs -0 -r ls -ld
```

**Explicação**: Este comando mostra quais diretórios **seriam deletados** (os mais antigos).

### 3️⃣ Contar backups locais e remotos

```bash
docker exec $(docker ps -q -f name=mysql-backup_mysql-backup) bash -c "
echo '=== Backups Locais ==='
find /backup -maxdepth 1 -type d -name '20*' | wc -l

echo '=== Backups Remotos ==='
rclone lsf gdrive:backups/mysql --dirs-only | grep '^20' | wc -l
"
```

### 4️⃣ Simular a limpeza (sem deletar - modo DEBUG)

```bash
docker exec $(docker ps -q -f name=mysql-backup_mysql-backup) bash -c '
#!/bin/bash

BACKUP_DIR=/backup
retention=7

echo "════════════════════════════════════════════"
echo "🧪 SIMULAÇÃO DE LIMPEZA (sem deletar)"
echo "════════════════════════════════════════════"
echo "Retenção configurada: $retention backups"
echo ""

echo "📊 Backups encontrados:"
find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" | sort | nl
echo ""

echo "🗑️ Backups que SERIAM deletados:"
find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" -print0 | sort -z | head -z -n -$retention | xargs -0 -r -I {} basename {}
echo ""

echo "✅ Backups que SERIAM mantidos (últimos $retention):"
find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" | sort | tail -n $retention | xargs -I {} basename {}
'
```

---

## 🐛 Problema Identificado

Vendo o código, percebi que pode haver um **bug sutil**. A linha atual é:

```bash
find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" -print0 | sort -z | head -n -$retention
```

### ❌ Problema: `sort` sem parâmetro de ordenação

O `sort -z` está ordenando **alfabeticamente**, não **cronologicamente**!

Isso funciona se os nomes estiverem no formato `YYYY-MM-DD_HH-MM-SS`, mas pode falhar em alguns casos.

---

## ✅ Solução Proposta

Vou criar uma versão corrigida do script. Aguarde...

