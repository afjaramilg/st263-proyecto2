#!/bin/bash

# fuentes:
# instalar gluster: https://docs.gluster.org/en/latest/Administrator-Guide/Setting-Up-Clients/
# set up: https://docs.gluster.org/en/latest/Administrator-Guide/Setting-Up-Clients/
# fstab options: https://docs.gluster.org/en/latest/Administrator-Guide/Setting-Up-Clients/
# ports (usar puertos para 3.4 or later): https://gluster.readthedocs.io/en/release-3.7.0-1/Troubleshooting/troubleshootingFAQ/

# 1. Cree un grupo de seguridad que incluya los puertos necesarios para usar gluster y SSH. 
# 2. Cree dos instancias, en dos regiones distintas, las dos pertenecientes al grupo de seguridad mencionado. A continuacion, incluimos las IP's de las instancias que nosotros usamos. IP1 esta en US-East-1b, IP2 esta en US-East-1b. A AMBAS AGREGUELES UN DISCO DE STORAGE EXTRA CUANDO LE PIDA "Add Storage".
IP1=10.0.4.157
IP2=10.0.1.181

# 3. Instale gluster en ambos servidores y encender el daemon
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:gluster/glusterfs-7
sudo apt update
sudo apt upgrade
sudo apt install glusterfs-server
sudo systemctl enable glusterd
sudo systemctl start glusterd

# 4. Corra este comando desde IP1 (no estamos seguros si hace diferencia correrlo desde uno o el otro). Esto agregara IP2 al pool de nuestro FS. El siguiente comando deberia mostar ambas instancias como parte de la lista.  
sudo gluster peer probe $IP2
sudo gluster pool list

# 5. (En ambos) Formatee el storage adicional que agrego al crear la instancia. Montelo en /mnt y agreguelo al fstab. Cree un directorio.
sudo mkfs.xfs /dev/xvdb
sudo mount /dev/xvdb /mnt
sudo sh -c "echo '/dev/xvdb               /mnt     xfs    defaults,discard        0 1'>> /etc/fstab"
sudo mkdir -p /mnt/gfsvolume/gv0


# 6. Corra estos comandos dese IP1. Esto crea el volumen compartido y lo activa. 
sudo gluster volume create distributed_vol transport tcp $IP1:/mnt/gfsvolume/gv0 $IP2:/mnt/gfsvolume/gv0
sudo gluster volume start distributed_vol


# 7. Los siguientes comandos se corren en el servidor web de donde se va a sacar el AMI. Primero se instala el client de gluster. Despues se crea un mount point para GlusterFS. Se monta el file system y se agrega el fstab. 
sudo apt update
sudo apt upgrade
sudo apt install glusterfs-client
sudo mkdir /mnt/gfsvol
sudo mount -t glusterfs $IP1:/distributed_vol /mnt/gfsvol
sudo sh -c "echo '$IP1:/distributed_vol /mnt/gfsvol  glusterfs defaults,_netdev 0 0'>> /etc/fstab"


