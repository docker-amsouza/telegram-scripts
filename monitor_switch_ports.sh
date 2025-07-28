#!/bin/bash
# monitor_switch_ports.sh
# Monitorar status das portas dos switches via SNMP
# Enviar alertas para Telegram quando o status de uma porta mudar.
#
# Como criar o bot Telegram e obter TOKEN e CHAT_ID:
# 1. Converse com @BotFather no Telegram e crie um novo bot (/newbot).
# 2. Anote o TOKEN fornecido (exemplo: 123456789:ABCdefGhIJKlmNoPQRstuVWxyz1234567890).
# 3. Inicie uma conversa com seu bot e envie qualquer mensagem.
# 4. Acesse: https://api.telegram.org/bot<TOKEN>/getUpdates
# 5. Na resposta JSON, encontre o campo "chat" e copie o "id".
# 6. Use esse valor na variável CHAT_ID abaixo.
#
# Configuração:
TOKEN="SEU_BOT_TOKEN_AQUI"
CHAT_ID="SEU_CHAT_ID_AQUI"
COMMUNITY="public"
TELEGRAM_SCRIPT="./telegram.sh"  # Caminho para o script de envio Telegram
STATUS_DIR="/tmp/status_switch_ports"

mkdir -p "$STATUS_DIR"

# Lista de switches para monitorar
# Formato:
# "IP_DO_SWITCH|NOME_DO_SWITCH|PORTA1:DESC1,PORTA2:DESC2,..."
switches=(
  "192.168.1.1|Switch-Exemplo|1:Porta Principal,2:Servidor,5:Access Point"
  "192.168.1.2|Switch-Backup|1:Core,3:Firewall"
)

send_telegram() {
    local message="$1"
    "$TELEGRAM_SCRIPT" "$TOKEN" "$CHAT_ID" "$message"
}

for switch_entry in "${switches[@]}"; do
    IFS='|' read -r ip switch_name ports <<< "$switch_entry"

    declare -A port_desc
    IFS=',' read -ra port_pairs <<< "$ports"
    for pair in "${port_pairs[@]}"; do
        IFS=':' read -r port desc <<< "$pair"
        port_desc["$port"]="$desc"
    done

    # SNMP walk do status das portas (ifOperStatus: 1=up, 2=down)
    snmpwalk -v2c -c "$COMMUNITY" "$ip" 1.3.6.1.2.1.2.2.1.8 | while read -r line; do
        if [[ "$line" =~ \.([0-9]+)\ =\ INTEGER:\ ([a-z]+)\(([0-9]+)\) ]]; then
            port_num="${BASH_REMATCH[1]}"
            status="${BASH_REMATCH[2]}" # up ou down

            desc="${port_desc[$port_num]:-Porta $port_num}"
            prev_status_file="$STATUS_DIR/$ip-$port_num.status"
            prev_status=""
            if [[ -f "$prev_status_file" ]]; then
                prev_status=$(<"$prev_status_file")
            fi

            if [[ "$status" != "$prev_status" ]]; then
                # Monta mensagem formatada em Markdown
                message="🔔 *Alerta de Porta no Switch*\n"
                message+="🖧 *Switch:* $switch_name ($ip)\n"
                message+="📌 *Porta:* $desc ($port_num)\n"
                message+="📡 *Status:* \`$status\`\n"
                message+="⏰ $(date '+%d/%m/%Y %H:%M:%S')"

                send_telegram "$message"

                echo "$status" > "$prev_status_file"
            fi
        fi
    done
done

# Exemplo de notificação que você receberá no Telegram:

# Quando a porta ficar **ativa** (up):
#
# 🔔 Alerta de Porta no Switch
# 🖧 Switch: Switch-Exemplo (192.168.1.1)
# 📌 Porta: Porta Principal (1)
# 📡 Status: up
# ⏰ 28/07/2025 18:00:00
#
# Quando a porta ficar **inativa** (down):
#
# 🔔 Alerta de Porta no Switch
# 🖧 Switch: Switch-Exemplo (192.168.1.1)
# 📌 Porta: Porta Principal (1)
# 📡 Status: down
# ⏰ 28/07/2025 18:15:43
