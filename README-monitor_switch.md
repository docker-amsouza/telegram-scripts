# monitor_switch_ports.sh

Script para monitorar status das portas dos switches via SNMP  
e enviar alertas no Telegram quando o status mudar.

---

## Como criar o bot Telegram e obter TOKEN e CHAT_ID

1. Abra o Telegram e inicie uma conversa com o @BotFather (https://t.me/BotFather).  
2. Envie o comando `/newbot` e siga as instruções para criar um novo bot.  
3. O @BotFather fornecerá o TOKEN do bot (exemplo: 123456789:ABCdefGhIJKlmNoPQRstuVWxyz1234567890).  
4. Salve este TOKEN e cole na variável TOKEN do seu script (ou no script telegram.sh).

Para descobrir seu CHAT_ID:  
1. Inicie uma conversa com seu bot no Telegram (procure o username do bot e envie uma mensagem qualquer).  
2. Acesse a URL abaixo substituindo `<TOKEN>` pelo token do seu bot:  
   https://api.telegram.org/bot<TOKEN>/getUpdates  
3. Na resposta JSON, encontre o campo `"chat"` e anote o valor do `"id"`.  
4. Cole esse valor na variável CHAT_ID do script.

---

## Configuração

Edite as variáveis no script:

- `TOKEN`: token do seu bot Telegram (normalmente configurado no script de envio de mensagens).  
- `CHAT_ID`: seu chat_id do Telegram.  
- `COMMUNITY`: comunidade SNMP (exemplo: "public").  
- `TELEGRAM_SCRIPT`: caminho para o script que envia mensagens ao Telegram.  
- `STATUS_DIR`: diretório onde o status anterior das portas será armazenado.  
- `switches`: lista dos seus switches no formato:

---

## Uso

Execute o script para monitorar o status das portas dos switches e enviar alertas via Telegram quando houver mudanças:

./monitor_switch_ports.sh

---

## Exemplo de entrada na variável switches

switches=(
  "192.168.1.1|Switch-Exemplo|1:Porta Principal,2:Servidor,5:Access Point"
  "192.168.1.2|Switch-Backup|1:Core,3:Firewall"
)

---

Autor: AMSouza  
Data: 2025-07-27
