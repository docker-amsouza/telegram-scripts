#!/bin/bash
# aironet-telegram.sh
# Monitorar logs Cisco Aironet para conexões/desconexões Wi-Fi
# Envia alertas formatados para Telegram com nomes amigáveis.
#
# Uso:
# - Configure TOKEN e CHAT_ID.
# - Adapte a lista MAC_TO_NAME com seus dispositivos.
# - Ajuste nomes dos APs na seção "case".
#
# Autor: AMSouza
# Data: 2025-07-27

LOG="/var/log/aironet-firewall.log"
TOKEN="SEU_BOT_TOKEN_AQUI"
CHAT_ID="SEU_CHAT_ID_AQUI"

# Converte MAC Cisco (xxxx.xxxx.xxxx) para padrão xx:xx:xx:xx:xx:xx
cisco_to_mac() {
    echo "$1" | tr -d '.' | sed -E 's/(..)(..)(..)(..)(..)(..)/\1:\2:\3:\4:\5:\6/' | tr '[:upper:]' '[:lower:]'
}

# Mapeamento MAC para nomes amigáveis
declare -A MAC_TO_NAME=(
    ["00:11:22:33:44:55"]="dispositivo-exemplo-1"
    ["66:77:88:99:aa:bb"]="dispositivo-exemplo-2"
    # Adicione seus MACs e nomes aqui
)

tail -F "$LOG" | while read -r line; do
    if echo "$line" | grep -q '%DOT11-6-ASSOC'; then
        MAC_CISCO=$(echo "$line" | grep -oE '[0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4}')
        MAC=$(cisco_to_mac "$MAC_CISCO")
        AP_RAW=$(echo "$line" | grep -oP 'Interface \K[^,]+')

        case "$AP_RAW" in
            Dot11Radio0) AP="VECTRA_GT 2.4G" ;;
            Dot11Radio1) AP="VECTRA_GT 5G" ;;
            *) AP="$AP_RAW" ;;
        esac

        RAW_DATE=$(echo "$line" | awk '{print $1" "$2" "$3}')
        FORMATTED_DATE=$(date -d "$RAW_DATE" '+%d/%m/%Y %H:%M:%S' 2>/dev/null)
        TIME=${FORMATTED_DATE:-$(date '+%d/%m/%Y %H:%M:%S')}

        NAME="${MAC_TO_NAME[$MAC]}"
        [[ -z "$NAME" ]] && NAME="🆕 Desconhecido"

        MSG=$(cat <<EOF
📶 Dispositivo Conectado
🖥️    AP: $AP
📛 Nome: $NAME
🔗 MAC: $MAC
🕒 Horário: $TIME
EOF
)

        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            --data-urlencode "text=$MSG"

    elif echo "$line" | grep -q '%DOT11-6-DISASSOC'; then
        MAC_CISCO=$(echo "$line" | grep -oE '[0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4}')
        MAC=$(cisco_to_mac "$MAC_CISCO")
        AP_RAW=$(echo "$line" | grep -oP 'Interface \K[^,]+')

        case "$AP_RAW" in
            Dot11Radio0) AP="VECTRA_GT 2.4G" ;;
            Dot11Radio1) AP="VECTRA_GT 5G" ;;
            *) AP="$AP_RAW" ;;
        esac

        RAW_DATE=$(echo "$line" | awk '{print $1" "$2" "$3}')
        FORMATTED_DATE=$(date -d "$RAW_DATE" '+%d/%m/%Y %H:%M:%S' 2>/dev/null)
        TIME=${FORMATTED_DATE:-$(date '+%d/%m/%Y %H:%M:%S')}

        NAME="${MAC_TO_NAME[$MAC]}"
        [[ -z "$NAME" ]] && NAME="🆕 Desconhecido"

        MSG=$(cat <<EOF
📴 Dispositivo Desconectado
🖥️    AP: $AP
📛 Nome: $NAME
🔗 MAC: $MAC
🕒 Horário: $TIME
EOF
)

        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            --data-urlencode "text=$MSG"
    fi
done

# Exemplo de notificação que você receberá no Telegram:

# 📶 Dispositivo Conectado
# 🖥️    AP:     WIFI 5G
# 📛 Nome:     smartphone-casa
# 🔗 MAC:      3a:5c:2d:9f:b7:e4
# 🕒 Horário:  28/07/2025 08:58:30

# 📴 Dispositivo Desconectado
# 🖥️    AP:     WIFI 2.4G
# 📛 Nome:     laptop-trabalho
# 🔗 MAC:      d4:6f:7a:1c:2b:90
# 🕒 Horário:  28/07/2025 17:42:10
