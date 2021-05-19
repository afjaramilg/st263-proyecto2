#!/bin/sh
# Este script se corria como un cronjob para montar automaticamente el bucket.  
docker-compose down
rm -rf /home/ec2-user/s3-mount
mkdir /home/ec2-user/s3-mount
s3fs s3-bucket-ssl-proyecto2 /home/ec2-user/s3-mount -o iam_role=iam-role-s3-proyecto2 -o allow_other
docker-compose -f /home/ec2-user/docker-compose.yml up -d
