#!/bin/bash
# Script de Teste de Webhook
# Testa o envio de notificações do container

echo "════════════════════════════════════════════"
echo "🔔 Teste de Webhook - MySQL Backup"
echo "════════════════════════════════════════════"
echo ""

# 1. Verificar se WEBHOOK_URL está configurado
echo "1️⃣ Verificando configuração do WEBHOOK_URL..."
if [ -z "${WEBHOOK_URL:-}" ]; then
    echo "❌ WEBHOOK_URL não está configurado!"
    echo "   Configure na sua stack.yml:"
    echo "   environment:"
    echo "     WEBHOOK_URL: https://seu-endpoint.com/webhook"
    exit 1
else
    echo "✅ WEBHOOK_URL configurado:"
    echo "   $WEBHOOK_URL"
fi
echo ""

# 2. Testar conectividade básica
echo "2️⃣ Testando conectividade com o endpoint..."
webhook_host=$(echo "$WEBHOOK_URL" | sed 's|https\?://||' | cut -d'/' -f1)
if ping -c 1 -W 2 "$webhook_host" > /dev/null 2>&1; then
    echo "✅ Host $webhook_host está acessível"
else
    echo "⚠️ Não foi possível fazer ping no host (pode ser normal se bloqueia ICMP)"
fi
echo ""

# 3. Testar envio de webhook de teste
echo "3️⃣ Enviando webhook de teste..."
test_payload=$(jq -n \
    --arg status "test" \
    --arg message "Teste de webhook do container MySQL Backup" \
    --arg timestamp "$(date -Iseconds)" \
    --arg hostname "$(hostname)" \
    '{status: $status, message: $message, timestamp: $timestamp, hostname: $hostname}')

echo "📦 Payload:"
echo "$test_payload" | jq '.'
echo ""

echo "🚀 Enviando POST request..."
response=$(curl -s -w "\n%{http_code}" -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$test_payload")

http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | head -n -1)

echo "📊 Resultado:"
echo "   HTTP Code: $http_code"
if [ -n "$body" ]; then
    echo "   Response Body: $body"
fi
echo ""

# 4. Avaliar resultado
if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ] || [ "$http_code" -eq 204 ]; then
    echo "✅ Webhook enviado com sucesso!"
    echo ""
    echo "🎉 Teste PASSOU - O webhook está funcionando!"
    echo "   Verifique se a notificação chegou no seu endpoint."
elif [ "$http_code" -eq 000 ]; then
    echo "❌ Falha ao conectar com o endpoint!"
    echo "   Possíveis causas:"
    echo "   - URL incorreta"
    echo "   - Firewall bloqueando conexões do container"
    echo "   - Endpoint fora do ar"
    echo "   - Problema de DNS"
    echo ""
    echo "🔍 Teste detalhado:"
    curl -v -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$test_payload" 2>&1 | head -20
else
    echo "⚠️ Webhook enviado mas retornou código: $http_code"
    echo "   O endpoint recebeu a requisição mas não retornou sucesso."
    echo "   Verifique os logs do seu endpoint."
fi
echo ""

# 5. Teste com curl verbose (opcional)
read -p "Deseja executar teste detalhado (verbose)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "5️⃣ Executando teste detalhado (curl -v)..."
    echo "════════════════════════════════════════════"
    curl -v -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$test_payload"
    echo ""
    echo "════════════════════════════════════════════"
fi

echo ""
echo "✅ Teste concluído!"

