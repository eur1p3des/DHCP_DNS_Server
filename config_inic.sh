#!/bin/bash
OPCSSH="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o loglevel=ERROR -i CLAU"

#CONFIG BÀSICA MÀQUINA
NOMMV="MAINS-Ernest"
RAMBASE=2048 # El contenidor de correu poste.io devora la RAM
DISCMV="./UbuSrvDockerNFS.vdi" #Aquest disc .vdi es: Ubuntu Server + user sjo/sjo amb sudo + apt install *nfs* i docker
IPINT="10.12.28.1"

#NOM XARXA INTERNA
nom_interf="ANGUERA"

#USERS
USER=sjo
username=ernest

#CREEM LA MÀQUINA VIRTUAL
echo "############ Creació de $NOMMV: Usuari: $nom
############ $RAMBASE RAM
############ $DISCMV DISC (adjunció multiple)
############ $IPINT/24
############ Headless, mode NAT, INTERNA i shell ssh port:2222 a $NOMMV ########"

echo "###############################Creem VM $NOMMV"

#MIREM SI LA MÀQUINA VIRTUAL EXISTEIX O NO
if VBoxManage list vms | grep -q "$NOMMV" ; then
    echo -n "Ja existeix la Màquina Virtual $NOMMV, Esborrem? (S/[N]";read -e RESP
    if [ "$RESP" = "S" ] ;then
        VBoxManage controlvm "$NOMMV" poweroff
        sleep 1
        VBoxManage unregistervm --delete "$NOMMV"
        sleep 1
    else
        mate-terminal --title=$NOMMV -x bash -c "ssh -p 2222 $OPCSSH $username@localhost" ## Ens connectem per ssh en cas que ja estigui creada
        exit 0
    fi
fi

#PARÀMETRES BÀSICS DE LA MÀQUINA VIRTUAL
VBoxManage createvm --name "$NOMMV" -register --ostype "Ubuntu_64"
VBoxManage storagectl "$NOMMV" --name jgdiscos --add ide
VBoxManage storageattach "$NOMMV" --storagectl jgdiscos --port 0 --device 0 --type hdd --medium "$DISCMV" --mtype immutable
vbTUNEJOS="--memory $RAMBASE --vram 32 --pae on --hwvirtex on --boot1 disk --audio none --accelerate3d on --usb off "
vbNICS="--nic1 nat --nictype1 virtio --nic2 intnet --nictype2 virtio --intnet2 $nom_interf"
VBoxManage modifyvm "$NOMMV" --ostype "Ubuntu_64" --ioapic off $vbTUNEJOS $vbNICS --natpf1 "guestssh,tcp,,2222,,22"

VBoxManage startvm "$NOMMV" --type headless

#Està engegada, escoltant via ssh pel port 2222

echo "###############################Generem claus ssh, sense contrasenya, per que no demani la contrasenya al entrar"
rm -v CLAU*
ssh-keygen -N "" -f CLAU
chmod 600 CLAU*

#FEM UN BULCE PER SI DE CAS LA MÀQUINA ENCARA NO S'HA ENGEGAT
FALLU=1
until [ "$FALLU" = "0" ] ; do
    echo -n "·"
    ssh-copy-id -p 2222 $OPCSSH.pub sjo@localhost
    FALLU="$?"
    sleep 1
done

#CREEM UNA COMMANDA PER A QUE NO ENS DEMANI LA PASSWORD
echo "###############################Comanda per que no demani password en fer sudo"
cat << FINAL >/tmp/cmd
echo '$USER ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
FINAL
scp -P 2222 $OPCSSH  /tmp/cmd $USER@localhost:/home/$USER/cmd
ssh -p 2222 $OPCSSH -t $USER@localhost bash "/home/$USER/cmd"

#CREACIÓ DEL MEU USUARI
echo "###############################Creació usuari"
cat << FINAL >/tmp/cmd
sudo useradd $username --shell /bin/bash
sudo passwd $username
sudo mkdir -p /home/$username/.ssh
sudo chown $username:$username -R /home/$username/
FINAL
scp -P 2222 $OPCSSH  /tmp/cmd $USER@localhost:/home/$USER/cmd
ssh -p 2222 $OPCSSH -t $USER@localhost bash "/home/$USER/cmd"

echo "###############################Comanda per que no demani password en fer sudo"

cat << FINAL >/tmp/cmd
echo 'ernest ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
FINAL
scp -P 2222 $OPCSSH  /tmp/cmd $USER@localhost:/home/$USER/cmd
ssh -p 2222 $OPCSSH -t $USER@localhost bash "/home/$USER/cmd"

ssh-copy-id -p 2222 $OPCSSH.pub $username@localhost


#GENEREM ELS FITXERS DE XARXA
echo "##############################Generem fitxer de config de xarxa:"
cat << FINAL > /tmp/netplan.yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: yes
      dhcp6: no
    enp0s8:
      dhcp4: no
      dhcp6: no
      addresses: [$IPINT/24]
#      gateway4: $DGMV
#      nameservers:
#        addresses: [8.8.8.8,8.8.4.4]
FINAL
scp -P 2222 $OPCSSH /tmp/netplan.yaml $USER@localhost:/home/$USER
CMD="ls ;
sudo hostnamectl set-hostname $NOMMV ;
sudo cp /home/$USER/netplan.yaml /etc/netplan/01-netcfg.yaml ;
sudo netplan apply;
"
ssh -p 2222 $OPCSSH -t $USER@localhost "bash -c $CMD"

echo "############################## Activem enrutament i NAT"
cat << "FINAL" > /tmp/cmd
cat $0
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -A FORWARD -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 10.12.28.0/24 -o enp0s3 -j MASQUERADE
FINAL
scp -P 2222 $OPCSSH  /tmp/cmd $USER@localhost:/home/$USER/cmd
ssh -p 2222 $OPCSSH -t $USER@localhost bash "/home/$USER/cmd"

echo "##############################Adaptem la xarxa xq no coincideixi amb la de VBox"
CMD="ls ;
sudo systemctl stop docker.service ;
"
ssh -p 2222 $OPCSSH -t $USER@localhost "bash -c $CMD"
cat << FINAL >/tmp/daemon.json
{
  "default-address-pools":
  [
  {"base":"10.66.0.0/16","size":24}
  ]
}
FINAL
scp -P 2222 $OPCSSH  /tmp/daemon.json $USER@localhost:/home/$USER/daemon.json
CMD="ls ;
sudo cp /home/$USER/daemon.json /etc/docker/daemon.json;
sudo systemctl start docker.service ;
"
ssh -p 2222 $OPCSSH -t $USER@localhost "bash -c $CMD"


scp -P 2222 $OPCSSH  /tmp/cmd $USER@localhost:/home/$USER/cmd
ssh -p 2222 $OPCSSH -t $USER@localhost bash "/home/$USER/cmd"

