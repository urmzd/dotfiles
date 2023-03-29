#!/usr/bin/env bash

# Set the latest release version of Docker Compose
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')

# Download the Docker Compose binary
sudo curl -L "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make the binary executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify that the installation was successful
docker-compose --version
