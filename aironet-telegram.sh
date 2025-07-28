#!/bin/bash
# aironet-telegram.sh
# Script para monitorar logs de conexão/desconexão Wi-Fi Cisco Aironet,
# e enviar alertas no Telegram com nome amigável dos dispositivos.
#
# Como criar o bot Telegram e obter o TOKEN e CHAT_ID para usar neste script:
#
# 1. Abra o Telegram e converse com o @BotFather (https://t.me/BotFather).
# 2. Envie o comando /newbot para criar um novo bot.
# 3. Siga as instruções para dar nome e username ao bot.
# 4. Após criado, o BotFather fornecerá um TOKEN (string parecida com 
#    123456789:ABCdefGhIJKlmNoPQRstuVWxyz1234567890).
# 5. Guarde esse TOKEN e cole na variável TOKEN do script.
#
# Para obter o CHAT_ID:
# 1. Inicie uma conversa com seu bot no Telegram (procure pelo username do bot e envie uma mensagem qualquer).
# 2. Acesse https://api.telegram.org/bot<TOKEN>/getUpdates substituindo <TOKEN> pelo token do seu bot.
# 3. Na resposta JSON, procure pelo campo "chat" e anote o "id" correspondente à sua conversa.
# 4. Cole esse valor na variável CHAT_ID do script.
#
# Pronto! Agora o script enviará notificações para o seu Telegram.
#
# Autor: AMSouza
# Data: 2025-07-27
# Uso: ./aironet-telegram.sh

LOG="/var/log/aironet-firewall.log"
TOKEN="SEU_BOT_TOKEN_AQUI"
CHAT_ID="SEU_CHAT_ID_AQUI"

# Função para converter MAC Cisco (xxxx.xxxx.xxxx) para padrão xx:xx:xx:xx:xx:xx
cisco_to_mac() {
    echo "$1" | tr -d '.' | sed -E 's/(..)(..)(..)(..)(..)(..)/\1:\2:\3:\4:\5:\6/' | tr '[:upper:]' '[:lower:]'
}

# Tabela genérica de nomes amigáveis por MAC
declare -A MAC_TO_NAME=(
    ["00:11:22:33:44:55"]="dispositivo-exemplo-1"
    ["66:77:88:99:aa:bb"]="dispositivo-exemplo-2"
    # Adicione seus dispositivos aqui
)

# Monitoramento em tempo real do log
tail -F "$LOG" | while read -r line; do
    if echo "$line" | grep -q '%DOT11-6-ASSOC'; then
        MAC_CISCO=$(echo "$line" | grep -oE '[0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4}')
        MAC=$(cisco_to_mac "$MAC_CISCO")
        AP=$(echo "$line" | grep -oP 'Interface \K[^,]+')

        # Nome amigável do AP (personalize aqui)
        case "$AP" in
            Dot11Radio0) AP="NOME_DO_SEU_AP_2_4G" ;;
            Dot11Radio1) AP="NOME_DO_SEU_AP_5G" ;;
            *) AP="$AP" ;;
        esac

        RAW_DATE=$(echo "$line" | awk '{print $1" "$2" "$3}')
        FORMATTED_DATE=$(date -d "$RAW_DATE" '+%d/%m/%Y %H:%M:%S' 2>/dev/null)
        TIME=${FORMATTED_DATE:-$(date '+%d/%m/%Y %H:%M:%S')}

        NAME="${MAC_TO_NAME[$MAC]}"
        [[ -z "$NAME" ]] && NAME="🆕 Desconhecido"

        MSG=$(printf "📶 Dispositivo Conectado\n🖥️   AP: %s\n📛 Nome: %s\n🔗 MAC: %s\n🕒 Horário: %s" "$AP" "$NAME" "$MAC" "$TIME")

        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            --data-urlencode "text=$MSG"

    elif echo "$line" | grep -q '%DOT11-6-DISASSOC'; then
        MAC_CISCO=$(echo "$line" | grep -oE '[0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4}')
        MAC=$(cisco_to_mac "$MAC_CISCO")
        AP=$(echo "$line" | grep -oP 'Interface \K[^,]+')

        case "$AP" in
            Dot11Radio0) AP="NOME_DO_SEU_AP_2_4G" ;;
            Dot11Radio1) AP="NOME_DO_SEU_AP_5G" ;;
            *) AP="$AP" ;;
        esac

        RAW_DATE=$(echo "$line" | awk '{print $1" "$2" "$3}')
        FORMATTED_DATE=$(date -d "$RAW_DATE" '+%d/%m/%Y %H:%M:%S' 2>/dev/null)
        TIME=${FORMATTED_DATE:-$(date '+%d/%m/%Y %H:%M:%S')}

        NAME="${MAC_TO_NAME[$MAC]}"
        [[ -z "$NAME" ]] && NAME="🆕 Desconhecido"

        MSG=$(printf "📴 Dispositivo Desconectado\n🖥️   AP: %s\n📛 Nome: %s\n🔗 MAC: %s\n🕒 Horário: %s" "$AP" "$NAME" "$MAC" "$TIME")

        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            --data-urlencode "text=$MSG"
    fi
done
