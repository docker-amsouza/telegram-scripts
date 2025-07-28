#!/bin/bash
# telegram.sh
#
# Script simples para enviar mensagens formatadas via Telegram Bot API usando MarkdownV2.
#
# Uso:
#   ./telegram.sh <CHAT_ID> "<ASSUNTO>" "<MENSAGEM>"
#
# Exemplo:
#   ./telegram.sh 123456789 "Alerta" "A porta 1 está inativa."
#
# Como criar o bot Telegram e obter TOKEN e CHAT_ID:
# 1. Converse com @BotFather no Telegram e crie um novo bot (/newbot).
# 2. Anote o TOKEN gerado (exemplo: 123456789:ABCdefGhIJKlmNoPQRstuVWxyz1234567890).
# 3. Inicie uma conversa com seu bot e envie qualquer mensagem.
# 4. Para obter o CHAT_ID, acesse:
#    https://api.telegram.org/bot<TOKEN>/getUpdates
# 5. Encontre o campo "chat" no JSON e anote o "id" correspondente.
#
# Configuração:
# - Substitua o valor da variável TOKEN pelo token do seu bot Telegram.
#
# Autor: AMSouza
# Data: 2025-07-27

TOKEN='SEU_BOT_TOKEN_AQUI'
CHAT_ID="$1"
SUBJECT="$2"
MESSAGE="$3"

# Função para escapar caracteres especiais no MarkdownV2
escape_markdown_v2() {
  echo "$1" | sed -e 's/\\/\\\\/g' \
                  -e 's/_/\\_/g' \
                  -e 's/\*/\\*/g' \
                  -e 's/\[/\\[/g' \
                  -e 's/\]/\\]/g' \
                  -e 's/(/\\(/g' \
                  -e 's/)/\\)/g' \
                  -e 's/~/\\~/g' \
                  -e 's/`/\\`/g' \
                  -e 's/>/\\>/g' \
                  -e 's/#/\\#/g' \
                  -e 's/+/\\+/g' \
                  -e 's/-/\\-/g' \
                  -e 's/=/\\=/g' \
                  -e 's/|/\\|/g' \
                  -e 's/{/\\{/g' \
                  -e 's/}/\\}/g' \
                  -e 's/\./\\./g' \
                  -e 's/!/\\!/g' \
                  -e 's/:/\\:/g'
}

SUBJECT_ESCAPED=$(escape_markdown_v2 "$SUBJECT")
MESSAGE_ESCAPED=$(escape_markdown_v2 "$MESSAGE")

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="*${SUBJECT_ESCAPED}*\n${MESSAGE_ESCAPED}" \
    -d parse_mode="MarkdownV2"

exit 0
