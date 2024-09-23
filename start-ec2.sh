#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y snapd git

sudo snap install docker
sudo usermod -aG docker $USER

# Clona o repositório
git clone https://github.com/JuanFricke/Atividade-AWS---Docker.git
cd seu_repositorio/wordpress

docker build -t wordpress_image .
docker run -d --name wordpress_container -p 8080:80 wordpress_image

echo "O ambiente foi configurado com sucesso e o WordPress está rodando no Docker."
