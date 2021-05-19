#!/bin/sh

# Instalar docker y docker compose
sudo apt update
sudo apt upgrade
sudo apt install docker.io
sudo groupadd docker
sudo usermod -aG docker ubuntu
sudo systemctl enable docker
sudo systemctl restart docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


# Instalar s3fs y montar bucket de s3
sudo amazon-linux-extras install epel -y
sudo yum install s3fs-fuse -y

mkdir s3-mount
sudo sh -c "echo "user_allow_other" >> /etc/fuse.conf"
#s3fs s3-bucket-ssl-proyecto2 /home/ec2-user/s3-mount -o iam_role=iam-role-s3-proyecto2 -o allow_other

