#!/bin/bash

# === Configurações ===

# Como criar o bot Telegram e obter TOKEN e CHAT_ID:
# 1. Converse com @BotFather no Telegram e crie um novo bot (/newbot).
# 2. Anote o TOKEN fornecido (exemplo: 123456789:ABCdefGhIJKlmNoPQRstuVWxyz1234567890).
# 3. Inicie uma conversa com seu bot e envie qualquer mensagem.
# 4. Acesse: https://api.telegram.org/bot<TOKEN>/getUpdates
# 5. Na resposta JSON, encontre o campo "chat" e copie o "id".
# 6. Use esse valor na variável CHAT_ID abaixo.
# 7. Configure o caminho correto para seu script de envio telegram.sh e o CHAT_ID.

MODEM_IP="IP_DO_MODEM_CISCO"                  # IP do modem Cisco
COMMUNITY="public"                            # Comunidade SNMP
LOG_FILE="/var/log/monitor_modem.log"        # Arquivo de log local
STATE_FILE="/tmp/modem_state.txt"             # Arquivo para salvar estado anterior
TELEGRAM_SCRIPT="/caminho/para/telegram.sh"  # Script para enviar alertas via Telegram
CHAT_ID="SEU_CHAT_ID_AQUI"                    # ID do chat do Telegram para receber alertas

# === Funções auxiliares ===

get_pppoe_status() {
    snmpwalk -v2c -c $COMMUNITY $MODEM_IP 1.3.6.1.2.1.2.2.1.8.1 | grep "up" >/dev/null && echo "UP" || echo "DOWN"
}

get_ip_publico() {
    curl -s https://ipinfo.io/ip
}

get_interface_traffic() {
    RX=$(snmpget -v2c -c $COMMUNITY $MODEM_IP 1.3.6.1.2.1.2.2.1.10.$1 | awk '{print $NF}')
    TX=$(snmpget -v2c -c $COMMUNITY $MODEM_IP 1.3.6.1.2.1.2.2.1.16.$1 | awk '{print $NF}')
    echo "$RX $TX"
}

get_uptime_raw() {
    snmpget -v2c -c $COMMUNITY $MODEM_IP 1.3.6.1.2.1.1.3.0 | grep -o '[0-9]\+'
}

convert_bytes_to_mbps() {
    echo "scale=2; $1 * 8 / 1000000" | bc
}

send_alert() {
    MSG="$1"
    echo "$(date) - $MSG" >> "$LOG_FILE"
    [ -x "$TELEGRAM_SCRIPT" ] && bash "$TELEGRAM_SCRIPT" "$CHAT_ID" "$MSG"
}

# === Estado anterior ===
[ -f "$STATE_FILE" ] && source "$STATE_FILE"

# === Coletas atuais ===
PPPOE_NOW=$(get_pppoe_status)
IP_NOW=$(get_ip_publico)
UPTIME_NOW=$(get_uptime_raw)
TRAFFIC_G0=$(get_interface_traffic 1)
TRAFFIC_G1=$(get_interface_traffic 2)

# === Verificações e alertas ===

# Verifica PPPoE
if [ "$PPPOE_NOW" != "$PPPOE_LAST" ]; then
    send_alert "⚠️ PPPoE mudou de estado: $PPPOE_LAST → $PPPOE_NOW"
fi

# Verifica troca de IP público
if [ "$IP_NOW" != "$IP_LAST" ]; then
    send_alert "🌐 IP público mudou: $IP_LAST → $IP_NOW"
fi

# Verifica reboot (uptime reiniciado)
if [ -n "$UPTIME_LAST" ] && [ "$UPTIME_NOW" -lt "$UPTIME_LAST" ]; then
    send_alert "🔄 Modem reiniciado! Uptime resetado."
fi

# Converte tráfego para Mbps e alerta
RX_G0=$(convert_bytes_to_mbps ${TRAFFIC_G0% *})
TX_G0=$(convert_bytes_to_mbps ${TRAFFIC_G0#* })
RX_G1=$(convert_bytes_to_mbps ${TRAFFIC_G1% *})
TX_G1=$(convert_bytes_to_mbps ${TRAFFIC_G1#* })

send_alert "📊 Gi0/0: RX=${RX_G0} Mbps, TX=${TX_G0} Mbps"
send_alert "📊 Gi0/1: RX=${RX_G1} Mbps, TX=${TX_G1} Mbps"

# === Salva estado atual ===
cat > "$STATE_FILE" <<EOF
PPPOE_LAST=$PPPOE_NOW
IP_LAST=$IP_NOW
UPTIME_LAST=$UPTIME_NOW
EOF

# Exemplo de notificações que você receberá no Telegram:
#
# ⚠️ PPPoE mudou de estado: DOWN → UP
# 🌐 IP público mudou: 187.45.123.10 → 187.45.123.25
# 🔄 Modem reiniciado! Uptime resetado.
# 📊 Gi0/0: RX=120.50 Mbps, TX=35.20 Mbps
# 📊 Gi0/1: RX=98.75 Mbps, TX=15.40 Mbps
#
# As mensagens são enviadas automaticamente sempre que alguma mudança for detectada.
