# telegram.sh

Script simples para enviar mensagens formatadas via Telegram Bot API usando Markdown.

---

## Uso

./telegram.sh <CHAT_ID> "<ASSUNTO>" "<MENSAGEM>"

Exemplo:  
./telegram.sh 123456789 "Alerta" "A porta 1 está inativa."

---

## Como criar o bot Telegram e obter TOKEN e CHAT_ID

1. Abra o Telegram e converse com o @BotFather.
2. Envie o comando /newbot e siga as instruções para criar um novo bot.
3. O BotFather irá fornecer o TOKEN do seu bot.
4. Inicie uma conversa com seu bot no Telegram (envie qualquer mensagem).
5. Para descobrir seu CHAT_ID, acesse a URL abaixo substituindo <TOKEN> pelo token do seu bot:  
   https://api.telegram.org/bot<TOKEN>/getUpdates
6. Procure o campo "chat" no JSON retornado e anote o valor do "id" — esse é seu CHAT_ID.

---

## Configuração

- Edite o arquivo telegram.sh.
- Substitua o valor da variável TOKEN pelo token do seu bot Telegram.
- O script recebe 3 parâmetros: CHAT_ID, assunto e mensagem.

---

## Exemplo de execução

./telegram.sh 123456789 "Alerta" "O servidor está offline."

---

## Autor

AMSouza  
Data: 2025-07-27
