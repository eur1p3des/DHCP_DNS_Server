

#CONFIGURACIÓ DEL DHCP

echo "############ Configuració DHCP"
cat << "FINAL" > /tmp/cmd
sudo apt update
sudo apt install isc-dhcp-server -y

#CONFIGUREM EL FITXER DHCPD.CONF
if [[ $(ip ad | grep "$IPINT") ]]; then
    interna=$(ip ad | grep "10.12.28.*/24" -B2 | head -1 | awk '{print $2}' |tr -d ":")
    echo -e "#Fitxer /etc/dhcp/dhcpd.conf" > /etc/dhcp/dhcpd.conf
    echo -e "#Dades globals del servidor" >> /etc/dhcp/dhcpd.conf
    echo -e "#ddns-update-style none;" >> /etc/dhcp/dhcpd.conf
    echo -e "default-lease-time 86400;" >> /etc/dhcp/dhcpd.conf
    echo -e "max-lease-time 604800;" >> /etc/dhcp/dhcpd.conf
    echo -e "" >> /etc/dhcp/dhcpd.conf
    echo -e "#El nostre servidor DNS" >> /etc/dhcp/dhcpd.conf
    echo -e "option domain-name-servers 10.12.28.1;" >> /etc/dhcp/dhcpd.conf
    echo -e "#El nom del nostre domini" >> /etc/dhcp/dhcpd.conf
    echo -e "option domain-name \"EAA.itb\";" >> /etc/dhcp/dhcpd.conf
    echo -e "" >> /etc/dhcp/dhcpd.conf
    echo -e "#Configurem la subnet." >> /etc/dhcp/dhcpd.conf
    echo -e "subnet 10.12.28.0 netmask 255.255.255.0 {" >> /etc/dhcp/dhcpd.conf
    echo -e "\t#Configurem el rang d'adreces IP" >> /etc/dhcp/dhcpd.conf
    echo -e "\trange 10.12.28.2 10.12.28.125;" >> /etc/dhcp/dhcpd.conf
    echo -e "\t#Indiquem quina és la màscara de la subnet" >> /etc/dhcp/dhcpd.conf
    echo -e "\toption subnet-mask 255.255.255.0;" >> /etc/dhcp/dhcpd.conf
    echo -e "\t#assignem l'adreça broadcast." >> /etc/dhcp/dhcpd.conf
    echo -e "\toption broadcast-address 10.12.28.255;" >> /etc/dhcp/dhcpd.conf
    echo -e "\t#Marquem quina serà l'adreça del router." >> /etc/dhcp/dhcpd.conf
    echo -e "\toption routers 10.12.28.1;" >> /etc/dhcp/dhcpd.conf
    echo -e "}" >> /etc/dhcp/dhcpd.conf

    sed -i "s/INTERFACESv4=\"\"/INTERFACESv4=\"$interna\"/g" /etc/default/isc-dhcp-server
else
    echo -e "INTERFAZ $IPINT NO ENCONTRADA"
fi

#CONFIGUREM LES IPTABLES PER A QUE ENS DONI INTERNET.
if [[ $(ip ad | grep "10.0.2") ]]; then
    NAT=$(ip ad | grep 10.0.2 -B2 | head -n1 | awk '{print $2}' | tr -d ":")

    sudo /sbin/iptables -P FORWARD ACCEPT
    sudo /sbin/iptables --table nat -A POSTROUTING -o $NAT -j MASQUERADE
else
echo -e "IP NAT NO ENCONTRADA"
fi
FINAL
scp -P 2222 $OPCSSH  /tmp/cmd $USER@localhost:/home/$USER/cmd
ssh -p 2222 $OPCSSH -t $USER@localhost 'sudo bash "/home/$USER/cmd"'

#ENCENEM EL SERVEI DHCP
ssh -p2222 $OPCSSH $username@localhost 'sudo systemctl start isc-dhcp-server'


