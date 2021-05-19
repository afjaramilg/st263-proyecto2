#!/bin/bash

# fuentes:
# instalar gluster: https://docs.gluster.org/en/latest/Administrator-Guide/Setting-Up-Clients/
# set up: https://docs.gluster.org/en/latest/Administrator-Guide/Setting-Up-Clients/
# fstab options: https://docs.gluster.org/en/latest/Administrator-Guide/Setting-Up-Clients/
# ports (usar puertos para 3.4 or later): https://gluster.readthedocs.io/en/release-3.7.0-1/Troubleshooting/troubleshootingFAQ/

# 1. Cree un grupo de seguridad que incluya los puertos necesarios para usar gluster y SSH. 
# 2. Cree dos instancias, en dos regiones distintas, las dos pertenecientes al grupo de seguridad mencionado. A continuacion, incluimos las IP's de las instancias que nosotros usamos. IP1 esta en US-East-1b, IP2 esta en US-East-1b
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

# 3. from the server that is going to be the primary, run this to check if it works
sudo gluster peer probe $IP2
sudo gluster pool list

# 4. mount the extra storage (and add it to fstab), format it first, this step is for both servers
sudo mkfs.xfs /dev/xvdb
sudo mount /dev/xvdb /mnt
sudo sh -c "echo "\n/dev/xvdb               /mnt     xfs    defaults,discard        0 1">> /etc/fstab"
sudo mkdir -p /mnt/gfsvolume/gv0


# 5. run these commands from the main server
sudo gluster volume create distributed_vol transport tcp $IP1:/mnt/gfsvolume/gv0 $IP2:/mnt/gfsvolume/gv0
sudo gluster volume start distributed_vol


# 6. at this point create a new server, the client, the instance where the AMI will come from. I am not sure if the "all-access" group is required but include it along with the web group.
sudo apt update
sudo apt upgrade
sudo apt install glusterfs-client
sudo mkdir /mnt/gfsvol
sudo mount -t glusterfs $IP1:/distributed_vol /mnt/gfsvol
sudo sh -c "echo "$IP1:/distributed_vol /mnt/gfsvol  glusterfs defaults,_netdev 0 0">> /etc/fstab"

# bob is, in fact, your uncle

