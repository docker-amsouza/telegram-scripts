Monitoramento do Modem Cisco 1941 com Alertas via Telegram

Script em Bash para monitorar o status do modem Cisco 1941 via SNMP, com alertas automatizados enviados para um bot Telegram. O monitoramento inclui:

- Estado da conexão PPPoE (conectado ou desconectado)
- Troca do IP público fornecido pelo provedor (DHCP)
- Reinício do modem (monitoramento pelo uptime)
- Consumo de banda nas interfaces físicas Gi0/0 e Gi0/1 (em Mbps)

---

Funcionalidades

- Detecção em tempo real do status PPPoE
- Notificação imediata em caso de troca do IP público
- Alerta sobre reinicializações do modem
- Monitoramento detalhado de tráfego de entrada e saída por interface
- Envio de notificações via Telegram usando bot customizado

---

Requisitos

Antes de executar o script, certifique-se de ter:

- SNMP configurado e habilitado no modem Cisco, com a comunidade correta
- Utilitários snmpget e snmpwalk instalados (pacote net-snmp-utils ou equivalente)
- Script de envio de mensagens Telegram (telegram.sh) devidamente configurado e funcional
- Acesso à internet para consultar o IP público (uso do curl)

---

Configurando seu Bot Telegram e obtendo TOKEN e CHAT_ID

1. Abra o Telegram e inicie uma conversa com o usuário oficial @BotFather (https://t.me/BotFather)
2. Envie o comando /newbot e siga as instruções para criar um novo bot
3. Anote o TOKEN gerado pelo BotFather (exemplo: 123456789:ABCdefGhIJKlmNoPQRstuVWxyz1234567890)
4. Inicie uma conversa com seu novo bot e envie qualquer mensagem para ativá-lo
5. No navegador, acesse:
   https://api.telegram.org/bot<TOKEN>/getUpdates
6. Na resposta JSON, localize a seção "chat" e copie o valor do campo "id" — este é seu CHAT_ID
7. Atualize seu script:
   - Coloque o TOKEN no arquivo telegram.sh
   - Defina o CHAT_ID no script principal de monitoramento
