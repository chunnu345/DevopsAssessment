#!/bin/bash

set -e

echo "✅ Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "✅ Installing required dependencies..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    git \
    unzip \
    nginx

echo "✅ Installing Docker..."

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Set up Docker stable repo
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

echo "✅ Installing Docker Compose..."

DOCKER_COMPOSE_VERSION="1.29.2"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

echo "✅ Initializing Docker Swarm (if not already initialized)..."

docker swarm init || echo "⚠️ Swarm may already be initialized"

echo "✅ Enabling NGINX..."
sudo systemctl enable nginx
sudo systemctl start nginx

echo "✅ Installing PHP CLI and Composer (for any CLI testing or Yii init scripts)..."
sudo apt install -y php-cli php-mbstring php-xml php-bcmath php-zip php-curl php-mysql php-gd php-fpm

# Optional: Install Composer globally
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    echo '❌ ERROR: Invalid composer installer signature'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
sudo mv composer.phar /usr/local/bin/composer
rm composer-setup.php

echo "✅ All dependencies installed successfully."
