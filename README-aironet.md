# aironet-telegram.sh

Script para monitorar logs de conexão/desconexão Wi-Fi Cisco Aironet  
e enviar alertas no Telegram com nome amigável dos dispositivos.

---

## Como criar o bot Telegram e obter TOKEN e CHAT_ID para usar neste script

1. Abra o Telegram e converse com o @BotFather (https://t.me/BotFather).  
2. Envie o comando `/newbot` para criar um novo bot.  
3. Siga as instruções para dar nome e username ao bot.  
4. Após criado, o BotFather fornecerá um TOKEN (exemplo: 123456789:ABCdefGhIJKlmNoPQRstuVWxyz1234567890).  
5. Guarde esse TOKEN e cole na variável TOKEN do script.

Para obter o CHAT_ID:  
1. Inicie uma conversa com seu bot no Telegram (procure pelo username do bot e envie uma mensagem qualquer).  
2. Acesse https://api.telegram.org/bot<TOKEN>/getUpdates substituindo <TOKEN> pelo token do seu bot.  
3. Na resposta JSON, procure pelo campo "chat" e anote o "id" correspondente à sua conversa.  
4. Cole esse valor na variável CHAT_ID do script.

---

## Configuração

- `LOG`: caminho do arquivo de log para monitoramento (exemplo: /var/log/aironet-firewall.log).  
- `TOKEN`: token do seu bot Telegram.  
- `CHAT_ID`: seu chat_id do Telegram.  
- `MAC_TO_NAME`: tabela associativa para mapear MACs a nomes amigáveis (adicione seus dispositivos).

---

## Funcionamento

O script monitora em tempo real o arquivo de log definido na variável `LOG`.  
Quando detecta uma conexão (`%DOT11-6-ASSOC`) ou desconexão (`%DOT11-6-DISASSOC`) de um dispositivo Wi-Fi Cisco Aironet, ele:  

- Converte o endereço MAC para o formato padrão (xx:xx:xx:xx:xx:xx).  
- Identifica o Access Point (AP) e substitui por nomes amigáveis configurados no script.  
- Formata a data e hora do evento.  
- Consulta o nome amigável do dispositivo pelo MAC.  
- Envia uma mensagem para o Telegram com as informações do evento.

---

## Autor

AMSouza  
Data: 2025-07-27
