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
TELEGRAM_SCRIPT="/usr/lib/zabbix/alertscripts/telegram.sh"
STATUS_DIR="/tmp/status_switch_ports"

# Lista de switches para monitorar
# Formato:
# "IP_DO_SWITCH|NOME_DO_SWITCH|PORTA1:DESC1,PORTA2:DESC2,..."
switches=(
  "192.168.1.1|Switch-Exemplo|1:Porta Principal,2:Servidor,5:Access Point"
  "192.168.1.2|Switch-Backup|1:Core,3:Firewall"
)

# Função para enviar alerta via Telegram
send_telegram() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
         -d chat_id="$CHAT_ID" \
         --data-urlencode "text=$message" >/dev/null
}

# Criar diretório para status se não existir
mkdir -p "$STATUS_DIR"

# Loop para monitorar switches
for switch_entry in "${switches[@]}"; do
    IFS='|' read -r ip switch_name ports <<< "$switch_entry"

    # Montar array de portas e descrições
    declare -A port_desc
    IFS=',' read -ra port_pairs <<< "$ports"
    for pair in "${port_pairs[@]}"; do
        IFS=':' read -r port num_desc <<< "$pair"
        port_desc["$port"]="$num_desc"
    done

    # Obter lista de interfaces e status via SNMP (ifOperStatus: 1=up, 2=down)
    # O OID ifOperStatus: 1.3.6.1.2.1.2.2.1.8
    snmpwalk -v2c -c "$COMMUNITY" "$ip" 1.3.6.1.2.1.2.2.1.8 | while read -r line; do
        # Exemplo de saída: IF-MIB::ifOperStatus.1 = INTEGER: up(1)
        if [[ "$line" =~ \.([0-9]+)\ =\ INTEGER:\ ([a-z]+)\(([0-9]+)\) ]]; then
            port_num="${BASH_REMATCH[1]}"
            status="${BASH_REMATCH[2]}" # up ou down

            desc="${port_desc[$port_num]:-Porta $port_num}"
            prev_status_file="$STATUS_DIR/$ip-$port_num.status"

            prev_status=""
            if [[ -f "$prev_status_file" ]]; then
                prev_status=$(<"$prev_status_file")
            fi

            # Se status mudou, envia alerta
            if [[ "$status" != "$prev_status" ]]; then
                message="🔔 Switch: $switch_name ($ip)
Porta: $desc ($port_num)
Status: $status
⏰ $(date '+%d/%m/%Y %H:%M:%S')"

                send_telegram "$message"

                echo "$status" > "$prev_status_file"
            fi
        fi
    done
done

# Exemplo de notificação que você receberá no Telegram:

# Quando a porta ficar **ativa** (up):
#
# 🔔 Switch: Switch-Core
# Porta: Porta Principal (1)
# Status: up
# ⏰ 28/07/2025 09:12:00
#
# Quando a porta ficar **inativa** (down):
#
# 🔔 Switch: Switch-Core
# Porta: Porta Principal (1)
# Status: down
# ⏰ 28/07/2025 09:12:00
