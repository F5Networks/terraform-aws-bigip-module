#!/bin/bash
sudo rm -rf /var/lib/cloud/*
sudo apt upgrade -y
sudo apt update -y
sudo apt install docker.io -y
sudo service docker start
sudo usermod -a -G docker $USER
sudo docker run --name docker-nginx -dit -p 9004:80 nginx:latest
sudo docker run --name juice-shop -dit -p 9000:3000 registry.hub.docker.com/bkimminich/juice-shop
sudo docker run --name web-dvwa -dit -p 9001:80 registry.hub.docker.com/vulnerables/web-dvwa
sudo docker run --name hackazon -dit -p 9002:80 registry.hub.docker.com/ianwijaya/hackazon
sudo docker run --name graphql -dit -p 9005:5013 -e WEB_HOST=0.0.0.0 dolevf/dvga