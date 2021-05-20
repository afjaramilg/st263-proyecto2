#!/bin/sh
# Instalar HAproxy
sudo apt update
sudo apt upgrade
sudo apt install haproxy -y

# Instalar Ruby y demas herramientas requeridas para el script 
sudo add-apt-repository ppa:brightbox/ruby-ng -y
sudo apt-get install software-properties-common ruby ruby-dev zlib1g-dev libxml2-dev build-essential libpcre3 libpcre3-dev -y

sudo gem install aws-sdk -y
sudo snap install core -y
sudo snap refresh core -y

# Instalar Certbot 
sudo snap install --classic certbot -y
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Generar un cert de certbot e crear un .pem para HAproxy 
sudo certbot certonly --standalone
sudo mkdir /etc/haproxy/certs
sudo sh -c "cat /etc/letsencrypt/live/lambda.cf/fullchain.pem /etc/letsencrypt/live/lambda.cf/privkey.pem > /etc/letsencrypt/live/lambda.cf/lambda.cf.pem"
sudo cp /etc/letsencrypt/live/lambda.cf/lambda.cf.pem /etc/haproxy/certs/lambda.cf.pem

# Mueva el archivo haproxy.cfg.template a /etc/haproxy/
sudo mv haproxy.cfg.template /etc/haproxy

# Cree un cronjob para periodicamente correr haproxy-script.rb, este actualizara la lista de instancias en HAproxy. 



