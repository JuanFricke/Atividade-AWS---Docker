# AWS - CONTAINERS
## Overview

This document outlines the steps to deploy a scalable WordPress application on AWS using the following components:

   - Amazon EC2 instances for hosting WordPress
   - Auto Scaling Group for scaling EC2 instances
   - Amazon RDS MySQL instance for the database
   - Elastic Load Balancer (ELB) to distribute traffic
   - Elastic File System (EFS) for static content storage

The deployment ensures high availability across multiple availability zones (AZs) and uses a private RDS instance, with traffic routed through the Load Balancer.
Architecture

The setup follows a classic three-tier architecture:

   - Web Tier: EC2 instances hosting WordPress.
   - Database Tier: RDS MySQL instance in a private subnet.
   - Load Balancer: Routes HTTP/HTTPS traffic to the EC2 instances.


## 1. Create a EC2 template

- Go to EC2 console
- Create a new template
- Name it "wordpress-template"
- Select "ubuntu 20.04 LTS" as the base image
- Select "t2.micro" as the instance type
- Add a volume of 16 GB
- select key pair "Wordpress"
- Add a security group with the name "sg-wordpress-ec2"
- Advanced details
  - Add user data:
```bash
  
#!/bin/bash

# Sai do script se algum comando falhar
set -e

LOG_FILE="script_log.txt"

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Atualizando pacotes e instalando dependências..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y snapd git mysql-client
sudo snap install aws-cli --classic

# Instalando Docker
log "Instalando Docker..."
sudo snap install docker
sleep 10

# Instalando Docker Compose
DOCKER_COMPOSE_VERSION="1.29.2"  # Versão do Docker Compose
log "Instalando Docker Compose versão $DOCKER_COMPOSE_VERSION..."
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verifica a instalação do Docker Compose
log "Verificando Docker Compose..."
sudo docker-compose --version

# Define as variáveis de ambiente do RDS
DB_HOST="database-wordpress-mysql.xxxxxxx.rds.amazonaws.com"
DB_USER="nome"
DB_PASSWORD="senha"
DB_NAME="wordpress"

# Cria o arquivo .env para armazenar as variáveis de ambiente
log "Criando arquivo .env com as variáveis de ambiente..."
cat <<EOF > .env
DB_HOST=$DB_HOST
DB_USER=$DB_USER
MYSQL_PWD=$DB_PASSWORD
DB_NAME=$DB_NAME
EOF

# Verifica se o banco de dados já existe, se não, cria o banco de dados
log "Verificando ou criando banco de dados $DB_NAME..."
export MYSQL_PWD="$DB_PASSWORD"
mysql --host="$DB_HOST" --user="$DB_USER" --execute="CREATE DATABASE IF NOT EXISTS $DB_NAME;"

# Testa a conexão com o banco de dados
log "Testando conexão com o banco de dados..."
if mysql --host="$DB_HOST" --user="$DB_USER" --execute="USE $DB_NAME;"; then
    log "Conexão bem-sucedida com o banco de dados $DB_NAME no host $DB_HOST."
else
    log "Falha na conexão com o banco de dados."
    exit 1
fi

# Cria o arquivo docker-compose.yml
log "Criando arquivo docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: '3'
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "80:80"
      - "8080:8080"
    environment:
      WORDPRESS_DB_HOST: \${DB_HOST}:3306
      WORDPRESS_DB_USER: \${DB_USER}
      WORDPRESS_DB_PASSWORD: \${MYSQL_PWD}
      WORDPRESS_DB_NAME: \${DB_NAME}
    volumes:
      - ./wp-content:/var/www/html/wp-content
EOF

# Inicia o ambiente Docker com Docker Compose
log "Iniciando ambiente Docker..."
sleep 10
sudo docker-compose -f /docker-compose.yml up 2>&1 | tee /docker-compose.log

log "O ambiente foi configurado com sucesso e o WordPress está rodando no Docker na porta 8080 e 80."

```

### sg-wordpress-ec2
![alt text](photos/sg-ec2-inbound_roules.png)


## 2. Create secure VPC network
![alt text](photos/vpc-resource_map.png)

![alt text](photos/vpc-resource_map2.png)

Each private subnet goes to a route table whit a route to a public NAT gateway.

All the public subnets go to a public route table with a route to the internet gateway.

All public subnets have a nat gateway, and all private subnets have a route table with a route to the nat gateway.

## 3. RDS

![alt text](photos/rds_1.png)

**Security group:**
```
	
sgr-01d21996856dcf27e
	
IPv4
	
MYSQL/Aurora
	
TCP
	
3306
	
0.0.0.0/16
```

![alt text](photos/rds_config.png)
