

#CONFIGURACIÓ DEL DNS
echo "####Configuració de dns"
cat << "FINAL" > /tmp/cmd

# Instal·lem bind9
sudo apt-get install bind9 -y

echo "# Per a crear el servei dns, primer hem d'editar el fitxer /etc/bind/named.conf.local"

# Insertem aquestes línies al fitxer per a crear la nostra zona i la reversa.
echo -e "#/etc/bind/named.conf.local" > /etc/bind/named.conf.local
echo -e "#ZONA ERNEST.ITB." >> /etc/bind/named.conf.local
echo -e "zone \"eaa.itb\"{" >> /etc/bind/named.conf.local
echo -e "\ttype master;" >> /etc/bind/named.conf.local
echo -e "\tfile \"/etc/bind/db.eaa.itb\";" >> /etc/bind/named.conf.local
echo -e "};" >> /etc/bind/named.conf.local
echo -e "#ZONA DE RESOLUCIÓ INVERSA" >> /etc/bind/named.conf.local
echo -e "zone \"28.12.10.in-addr.arpa\" {" >> /etc/bind/named.conf.local
echo -e "\ttype master;" >> /etc/bind/named.conf.local
echo -e "\tfile \"/etc/bind/db.25\";" >> /etc/bind/named.conf.local
echo -e "};" >> /etc/bind/named.conf.local
echo "#-------------------------------------------------------------------------------------------------------------"
echo "# Ara configurem el fitxer /etc/bind/db.eaa.itb"
sudo touch /etc/bind/db.eaa.itb
echo -e "; DEFINICIÓ DE LA ZONA EAA.ITB" > /etc/bind/db.eaa.itb
echo -e "\$TTL 604800" >> /etc/bind/db.eaa.itb
echo -e "eaa.itb. IN SOA router.eaa.itb. sjo.router.eaa.itb. (" >> /etc/bind/db.eaa.itb
echo -e "\t20201020; versió" >> /etc/bind/db.eaa.itb
echo -e "\t1D   ; temps d'espera per refrescar" >> /etc/bind/db.eaa.itb
echo -e "\t2H   ; temps de reintent" >> /etc/bind/db.eaa.itb
echo -e "\t1W   ; Caducitat" >> /etc/bind/db.eaa.itb
echo -e "\t2D ) ; ttl" >> /etc/bind/db.eaa.itb
echo -e "" >> /etc/bind/db.eaa.itb
echo -e "@             IN   NS   router.eaa.itb." >> /etc/bind/db.eaa.itb
echo -e "localhost     IN   A    127.0.0.1" >> /etc/bind/db.eaa.itb
echo -e "router        IN   A    10.12.28.1" >> /etc/bind/db.eaa.itb
echo -e "web11         IN   A    10.12.28.1" >> /etc/bind/db.eaa.itb
echo -e "web22         IN   A    10.12.28.1" >> /etc/bind/db.eaa.itb
echo -e "monitor       IN   A    10.12.28.1" >> /etc/bind/db.eaa.itb
echo -e "traefik       IN   A    10.12.28.1" >> /etc/bind/db.eaa.itb
echo -e "bdd           IN   A    10.12.28.2" >> /etc/bind/db.eaa.itb
echo -e "eq1           IN   A    10.12.28.101" >> /etc/bind/db.eaa.itb
echo -e "eq2           IN   A    10.12.28.102" >> /etc/bind/db.eaa.itb
echo -e "WWW           IN   CNAME bdd" >> /etc/bind/db.eaa.itb

echo "#---------------------------------------------------------------------------------------------------------------"
echo "# PER ÚLTIM, CONFIGUREM L'ARXIU DB.25"

echo -e "\$TTL 604800" > /etc/bind/db.25
echo -e "28.12.10.in-addr.arpa. IN SOA router.eaa.itb. is.router.eaa.itb. (" >> /etc/bind/db.25
echo -e "\t20201020  ; versió" >> /etc/bind/db.25
echo -e "\t1D   ; temps d'espera per refrescar" >> /etc/bind/db.25
echo -e "\t2H   ; temps de reintent" >> /etc/bind/db.25
echo -e "\t1W   ; Caducitat" >> /etc/bind/db.25
echo -e "\t2D ) ; ttl" >> /etc/bind/db.25
echo -e "" >> /etc/bind/db.25
echo -e "	     IN  NS  	router.eaa.itb." >> /etc/bind/db.25
echo -e "1           IN  PTR    router.eaa.itb." >> /etc/bind/db.25
echo -e "1           IN  PTR    web11.eaa.itb." >> /etc/bind/db.25
echo -e "1           IN  PTR    web22.eaa.itb." >> /etc/bind/db.25
echo -e "1           IN  PTR    monitor.eaa.itb." >> /etc/bind/db.25
echo -e "1           IN  PTR    traefik.eaa.itb." >> /etc/bind/db.25
echo -e "2	         IN  PTR    bdd.eaa.itb." >> /etc/bind/db.25
echo -e "101	     IN  PTR    eq1.eaa.itb." >> /etc/bind/db.25
echo -e "102	     IN  PTR    eq2.eaa.itb." >> /etc/bind/db.25

FINAL

scp -P 2222 $OPCSSH  /tmp/cmd $USER@localhost:/home/$USER/cmd
ssh -p 2222 $OPCSSH -t $USER@localhost 'sudo bash "/home/$USER/cmd"'

#Encenem el serveri DNS i el servei DHCP
ssh -p2222 $OPCSSH $username@localhost 'sudo systemctl restart isc-dhcp-server'
ssh -p2222 $OPCSSH $username@localhost 'sudo systemctl restart bind9'
