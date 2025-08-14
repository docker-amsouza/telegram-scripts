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
# Configurações
COMMUNITY="public"
CHAT_ID="SEU_CHAT_ID_AQUI"
STATUS_DIR="/tmp/status_portas"
TELEGRAM_SCRIPT="/usr/lib/zabbix/alertscripts/telegram.sh"
LOG_FILE="/tmp/monitor_switch_ports.log"

mkdir -p "$STATUS_DIR"

echo "$(date '+%F %T') - Início do monitoramento" >> "$LOG_FILE"

# Lista de switches no formato: IP|Nome|Porta:Descrição,...
switches=(
  "192.168.0.1|🖧 SWITCH_1|1:Servidor,2:Firewall"
  "192.168.0.2|🖧 SWITCH_2|3:Access-Point,5:Impressora"
)

for entry in "${switches[@]}"; do
  IFS='|' read -r ip name portas_descr <<< "$entry"

  declare -A descricoes=()
  IFS=',' read -ra pares <<< "$portas_descr"
  for par in "${pares[@]}"; do
    IFS=':' read -r porta desc <<< "$par"
    descricoes["$porta"]="$desc"
  done

  while read -r line; do
    if [[ "$line" =~ \.([0-9]+)\ =\ INTEGER:\ ([0-9]+) ]]; then
      porta="${BASH_REMATCH[1]}"
      status="${BASH_REMATCH[2]}"

      STATUS_FILE="$STATUS_DIR/${ip//./_}_porta_${porta}.status"
      old_status=""
      [ -f "$STATUS_FILE" ] && old_status=$(<"$STATUS_FILE")

      echo "$(date '+%F %T') - Switch $name, porta $porta, status atual: $status, status antigo: $old_status" >> "$LOG_FILE"

      if [ "$status" != "$old_status" ]; then
        echo "$status" > "$STATUS_FILE"

        case "$status" in
          1)
            emoji="✅"
            estado="ATIVA (UP)"
            ;;
          2)
            emoji="🚨"
            estado="INATIVA (DOWN)"
            ;;
          *)
            emoji="❓"
            estado="DESCONHECIDA"
            ;;
        esac

        descricao="${descricoes[$porta]:-Porta $porta}"
        descricao_esc=$(echo "$descricao" | sed -e 's/_/\\_/g' -e 's/\*/\\*/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/(/\\(/g' -e 's/)/\\)/g')

        mensagem="🔔 *Alerta de Porta no Switch* $name\n"
        mensagem+="$emoji A porta *$porta* (_$descricao_esc_) está agora *$estado*\n"
        mensagem+="🖧 Switch: $name\n"
        mensagem+="📍 IP: $ip"

        assunto="Alerta Porta Switch"

        echo "$(date '+%F %T') - Enviando alerta para porta $porta no switch $name com status $status" >> "$LOG_FILE"

        "$TELEGRAM_SCRIPT" "$CHAT_ID" "$assunto" "$mensagem"
      fi
    fi
  done < <(snmpwalk -v2c -c "$COMMUNITY" "$ip" 1.3.6.1.2.1.2.2.1.8 2>/dev/null)

  unset descricoes
done

# Exemplo real de notificação que você receberá no Telegram:

# Quando a porta ficar **ativa** (UP):
# 🔔 *Alerta de Porta no Switch* SWITCH_1
# ✅ A porta *1* (_Servidor_) está agora *ATIVA (UP)*
# 🖧 Switch: SWITCH_1
# 📍 IP: 192.168.0.1
#
# Quando a porta ficar **inativa** (DOWN):
# 🔔 *Alerta de Porta no Switch* SWITCH_2
# 🚨 A porta *2* (_Firewall_) está agora *INATIVA (DOWN)*
# 🖧 Switch: SWITCH_2
# 📍 IP: 192.168.0.2
