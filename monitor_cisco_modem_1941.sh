#!/bin/bash
# Como criar o bot Telegram e obter TOKEN e CHAT_ID:
# 1. Converse com @BotFather no Telegram e crie um novo bot (/newbot).
# 2. Anote o TOKEN fornecido (exemplo: 123456789:ABCdefGhIJKlmNoPQRstuVWxyz1234567890).
# 3. Inicie uma conversa com seu bot e envie qualquer mensagem.
# 4. Acesse: https://api.telegram.org/bot<TOKEN>/getUpdates
# 5. Na resposta JSON, encontre o campo "chat" e copie o "id".
# 6. Use esse valor na variável CHAT_ID abaixo.
# 7. Configure o caminho correto para seu script de envio telegram.sh e o CHAT_ID.
#
# Autor: AMSouza
# Data: 2025-07-27
#
# === Configurações ===

MODEM_IP="IP_DO_MODEM"                  # IP do modem
COMMUNITY="public"                      # Comunidade SNMP
LOG_FILE="/var/log/monitor_modem.log"   # Arquivo de log local
STATE_FILE="/tmp/modem_state.txt"       # Arquivo para salvar estado anterior
TELEGRAM_SCRIPT="/caminho/para/telegram.sh"  # Script para enviar alertas via Telegram
CHAT_ID="SEU_CHAT_ID_AQUI"              # ID do chat do Telegram

GIGA_IFS=(2 3)       # Índices SNMP das interfaces Gigabit
DIALER_IFINDEX=8     # Índice SNMP do Dialer1
INTERVAL=60          # Intervalo para cálculo Mbps

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$STATE_FILE")"

# === Funções auxiliares ===

get_if_descr() { snmpget -v2c -c "$COMMUNITY" "$MODEM_IP" 1.3.6.1.2.1.2.2.1.2.$1 -Ovq 2>/dev/null; }
get_port_status() { snmpget -v2c -c "$COMMUNITY" "$MODEM_IP" 1.3.6.1.2.1.2.2.1.8.$1 -Ovq 2>/dev/null; }

get_traffic_64() {
    RX=$(snmpget -v2c -c "$COMMUNITY" "$MODEM_IP" 1.3.6.1.2.1.31.1.1.1.6.$1 -Ovq 2>/dev/null)
    TX=$(snmpget -v2c -c "$COMMUNITY" "$MODEM_IP" 1.3.6.1.2.1.31.1.1.1.10.$1 -Ovq 2>/dev/null)
    echo "$RX $TX"
}

get_traffic_32() {
    RX=$(snmpget -v2c -c "$COMMUNITY" "$MODEM_IP" 1.3.6.1.2.1.2.2.1.10.$1 -Ovq 2>/dev/null)
    TX=$(snmpget -v2c -c "$COMMUNITY" "$MODEM_IP" 1.3.6.1.2.1.2.2.1.16.$1 -Ovq 2>/dev/null)
    echo "$RX $TX"
}

convert_to_mbps() {
    awk "BEGIN {printf \"%.2f\", ($1*8)/($2*1000000)}"
}

get_public_ip_snmp() {
    for ip in $(snmpwalk -v2c -c "$COMMUNITY" "$MODEM_IP" 1.3.6.1.2.1.4.20.1.1 -Ovq 2>/dev/null); do
        ifIndex=$(snmpget -v2c -c "$COMMUNITY" "$MODEM_IP" 1.3.6.1.2.1.4.20.1.2.$ip -Ovq 2>/dev/null)
        if [ "$ifIndex" -eq "$DIALER_IFINDEX" ]; then
            echo "$ip"
            return
        fi
    done
    echo "N/A"
}

# Escapa caracteres especiais do MarkdownV2
escape_md2() {
    local text="$1"
    text="${text//\\/\\\\}"
    text="${text//`/\\`}"
    text="${text//_/\\_}"
    text="${text//\*/\\*}"
    text="${text//\[/\\[}"
    text="${text//\]/\\]}"
    text="${text//\(/\\(}"
    text="${text//\)/\\)}"
    text="${text//#/\\#}"
    text="${text//\+/\\+}"
    text="${text//-/\\-}"
    text="${text//=/\\=}"
    text="${text//|/\\|}"
    text="${text//./\\.}"
    text="${text//!/\\!}"
    echo "$text"
}

send_alert() {
    local msg="$1"
    echo "$(date '+%F %T') - Enviando alerta" >> "$LOG_FILE"
    [ -x "$TELEGRAM_SCRIPT" ] && bash "$TELEGRAM_SCRIPT" "$CHAT_ID" "$msg"
}

# === Estado anterior ===
declare -A old_rx old_tx old_status
old_ip_public=""
[ -f "$STATE_FILE" ] && source "$STATE_FILE"

full_msg=""

process_interface() {
    local ifIndex=$1 use_64bits=$2
    local ifDescr=$(get_if_descr "$ifIndex")
    ifDescr=$(escape_md2 "$ifDescr")
    local status=$(get_port_status "$ifIndex")
    local traffic
    if [ "$use_64bits" = "yes" ]; then
        traffic=($(get_traffic_64 "$ifIndex"))
    else
        traffic=($(get_traffic_32 "$ifIndex"))
    fi
    local rx_now=${traffic[0]:-0}
    local tx_now=${traffic[1]:-0}
    local delta_rx=$((rx_now - ${old_rx[$ifIndex]:-0}))
    local delta_tx=$((tx_now - ${old_tx[$ifIndex]:-0}))
    if [ "$use_64bits" != "yes" ]; then
        [ $delta_rx -lt 0 ] && delta_rx=$((rx_now + 4294967296 - ${old_rx[$ifIndex]:-0}))
        [ $delta_tx -lt 0 ] && delta_tx=$((tx_now + 4294967296 - ${old_tx[$ifIndex]:-0}))
    fi
    local rx_rate=$(convert_to_mbps "$delta_rx" "$INTERVAL")
    local tx_rate=$(convert_to_mbps "$delta_tx" "$INTERVAL")
    case "$status" in
        1) emoji_status="✅" ;;
        2) emoji_status="🚨" ;;
        5) emoji_status="⚠️" ;;
        *) emoji_status="❓" ;;
    esac
    full_msg+="📊 Interface: \`$ifDescr\` $emoji_status"$'\n'"RX: $rx_rate Mbps TX: $tx_rate Mbps"$'\n\n'
    old_rx[$ifIndex]=$rx_now
    old_tx[$ifIndex]=$tx_now
    old_status[$ifIndex]=$status
}

# === Processamento ===
for ifIndex in "${GIGA_IFS[@]}"; do
    process_interface "$ifIndex" yes
done
process_interface "$DIALER_IFINDEX" no

current_ip=$(get_public_ip_snmp)
current_ip=$(escape_md2 "$current_ip")
full_msg+="🌐 IP público: \`$current_ip\`"

send_alert "$full_msg"

# === Salva estado atual ===
{
    for i in "${!old_rx[@]}"; do
        echo "old_rx[$i]=${old_rx[$i]}"
        echo "old_tx[$i]=${old_tx[$i]}"
        echo "old_status[$i]=${old_status[$i]}"
    done
    echo "old_ip_public=\"$current_ip\""
} > "$STATE_FILE"

# === Exemplo de notificações que você receberá no Telegram ===
#
# ⚠️ PPPoE mudou de estado: DOWN → UP
# 🌐 IP público mudou: 187.45.123.10 → 187.45.123.25
# 🔄 Modem reiniciado! Uptime resetado.
# 📊 Gi0/2: RX=120.50 Mbps, TX=35.20 Mbps
# 📊 Gi0/3: RX=98.75 Mbps, TX=15.40 Mbps
# 🌐 IP público: 187.45.123.25
#
# As mensagens são enviadas automaticamente sempre que alguma mudança for detectada.
# Você deve substituir MODEM_IP, CHAT_ID e TELEGRAM_SCRIPT pelos valores corretos.
