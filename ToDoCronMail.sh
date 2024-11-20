#!/bin/bash
# Будет отображаться "От кого"
FROM=star@bet.ru
# Кому
MAILTO=ger@gmail.com
# Тема письма
NAME=$Релиз-кандидат-3.0.480
# Тело письма
BODY=$/home/thor/bin/mail/Пн12:00Релиз-кандидат3.0.480.html
# В моем примере я отправляю письма через существующий почтовый ящик на gmail.com
# Скрипт легко адаптируется для любых почтовых серверов
SMTPSERVER=mail.marathonbet.ru
# Логин и пароль от учетной записи gmail.com
SMTPLOGIN=***
SMTPPASS=***
 
# Отправляем письмо
/home/dev/.thunderbird/gor5u43j.default/Mail -f $FROM -t $MAILTO -o message-charset=utf-8  -u $NAME -m $BODY -s $SMTPSERVER -o tls=yes -xu $SMTPLOGIN -xp $SMTPPASS

