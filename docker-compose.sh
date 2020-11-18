
# Instal·lem i configurem el docker-compose per a poder aixecar els nostres servidors web.
ssh -p 2222 $OPCSSH $username@localhost 'sudo chmod apt-get install -y curl'
ssh -p 2222 $OPCSSH $username@localhost 'sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose'
ssh -p 2222 $OPCSSH $username@localhost 'sudo chmod +x /usr/local/bin/docker-compose'

# Descarrego el meu repositori de github amb les configuracions.
ssh -p 222 $OPCSSH $username@localhost 'git clone https://github.com/ernest-hue/serv_web.git'
ssh -p 222 $OPCSSH $username@localhost 'chmod +x /home/$username/serv_web/*.sh'
ssh -p 222 $OPCSSH $username@localhost 'bash /home/$username/serv_web/run.sh'
