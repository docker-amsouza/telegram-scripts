# Monitor Switch Ports

Script em Bash para monitorar o status das portas de switches via SNMP e enviar alertas para o Telegram quando o status mudar.

## 📌 Funcionalidades
- Consulta SNMP para verificar status **UP/DOWN** das portas.
- Envia mensagens formatadas para um chat no Telegram.
- Salva estado anterior das portas para evitar alertas repetidos.

## 🛠 Requisitos
- **Bash**
- **SNMP** (`snmpwalk`)
- Bot do Telegram configurado
- Script auxiliar `telegram.sh`

## ⚙️ Configuração

### Criando o Bot no Telegram e obtendo TOKEN e CHAT_ID
1. Abra o Telegram e inicie uma conversa com o **@BotFather**.
2. Envie o comando `/newbot` e siga as instruções para criar um novo bot.
3. O BotFather fornecerá o **TOKEN** (exemplo: `123456789:ABCdefGhIJKlmNoPQRstuVWxyz1234567890`).
4. Salve este TOKEN no script `telegram.sh` ou no seu script principal.

**Para descobrir seu CHAT_ID:**
1. Inicie uma conversa com seu bot no Telegram (procure pelo username do bot e envie qualquer mensagem).
2. Acesse no navegador:  
   https://api.telegram.org/bot<TOKEN>/getUpdates  
   (substitua `<TOKEN>` pelo token do seu bot).
3. Na resposta JSON, encontre o campo `"chat"` e anote o valor de `"id"`.
4. Cole este valor na variável `CHAT_ID` do script.

---

### Editando o Script
No arquivo `monitor_switch_ports.sh` configure:
- `TOKEN` → Token do seu bot Telegram (no `telegram.sh` ou direto no script)
- `CHAT_ID` → Seu chat_id no Telegram
- `COMMUNITY` → Comunidade SNMP (exemplo: `"public"`)
- `TELEGRAM_SCRIPT` → Caminho para o script que envia mensagens
- `STATUS_DIR` → Diretório para armazenar o status anterior
- `switches` → Lista de switches e portas a monitorar

**Exemplo de entrada para `switches`:**
switches=(
  "192.168.1.1|Switch-Exemplo|1:Porta Principal,2:Servidor,5:Access Point"
  "192.168.1.2|Switch-Backup|1:Core,3:Firewall"
)

---

## ▶ Uso
Dê permissão de execução e execute:
chmod +x monitor_switch_ports.sh
./monitor_switch_ports.sh

---

**Autor:** AMSouza  
**Data:** 27/07/2025
