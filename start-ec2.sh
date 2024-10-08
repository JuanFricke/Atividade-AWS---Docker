#!/bin/bash

# Saia do script se algum comando falhar
set -e

# Definir o arquivo de log
LOG_FILE="script_log.txt"

# Função para registrar mensagens no log e no terminal
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Atualiza e instala pacotes necessários
log "Atualizando pacotes e instalando dependências..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y snapd git mysql-client nfs-common

# Instala AWS CLI
log "Instalando AWS CLI..."
sudo snap install aws-cli --classic

# Instala Docker
log "Instalando Docker..."
sudo snap install docker

# Certifique-se de que o Docker está rodando
log "Esperando Docker iniciar..."
sleep 10

# Instala o Docker Compose
DOCKER_COMPOSE_VERSION="1.29.2"  # Versão do Docker Compose
log "Instalando Docker Compose versão $DOCKER_COMPOSE_VERSION..."
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verifica a instalação do Docker Compose
log "Verificando Docker Compose..."
sudo docker-compose --version

# Define as variáveis de ambiente do RDS
DB_HOST="database-wordpress-mysql.x.us-east-1.rds.amazonaws.com"
DB_USER="x"
DB_PASSWORD="x"
DB_NAME="x"

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

# Configura o EFS
EFS_DNS="fs-x.efs.us-east-1.amazonaws.com"
MOUNT_POINT="/mnt/efs"

log "Montando EFS em $MOUNT_POINT..."
sudo mkdir -p $MOUNT_POINT
sudo mount -t nfs4 -o nfsvers=4.1 $EFS_DNS:/ $MOUNT_POINT

# Cria o arquivo docker-compose.yml diretamente no script
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
      - $MOUNT_POINT/wp-content:/var/www/html/wp-content
EOF

# Inicia o ambiente Docker com Docker Compose
log "Iniciando ambiente Docker..."
sleep 10
sudo docker-compose -f /docker-compose.yml up 2>&1 | tee /docker-compose.log

# Exibe mensagem de sucesso
log "O ambiente foi configurado com sucesso e o WordPress está rodando no Docker na porta 8080."