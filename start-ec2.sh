#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y snapd git awscli
# aws s3 cp s3://.env

sudo snap install docker
sudo usermod -aG docker $USER

# Clona o repositório
git clone https://github.com/JuanFricke/Atividade-AWS---Docker.git

docker-compose up

echo "O ambiente foi configurado com sucesso e o WordPress está rodando no Docker."
