#!/bin/bash

set -euo pipefail
clear

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Function to print messages
print_message() {
  local color=$1
  local message=$2
  printf "${color}${message}${NC}\n"
}

print_message "${GREEN}" "
███╗   ██╗ ██████╗ ██████╗ ███████╗    ███████╗██╗  ██╗██████╗  ██████╗ ██████╗ ████████╗███████╗██████╗
████╗  ██║██╔═══██╗██╔══██╗██╔════╝    ██╔════╝╚██╗██╔╝██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
██╔██╗ ██║██║   ██║██║  ██║█████╗      █████╗   ╚███╔╝ ██████╔╝██║   ██║██████╔╝   ██║   █████╗  ██████╔╝
██║╚██╗██║██║   ██║██║  ██║██╔══╝      ██╔══╝   ██╔██╗ ██╔═══╝ ██║   ██║██╔══██╗   ██║   ██╔══╝  ██╔══██╗
██║ ╚████║╚██████╔╝██████╔╝███████╗    ███████╗██╔╝ ██╗██║     ╚██████╔╝██║  ██║   ██║   ███████╗██║  ██║
╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝    ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
"

# 1. Check for the Architecture and kernel
ARCHITECTURE=$(uname -m)
if [[ ${ARCHITECTURE} == "amd64" || ${ARCHITECTURE} == "x86_64" ]]; then
  ARCHITECTURE="amd64"
elif [[ ${ARCHITECTURE} == "arm64" ]]; then
  ARCHITECTURE="arm64"
else
  print_message "${RED}" "Sorry: $(uname -a) architecture not supported by this script"
  exit 1
fi
print_message "${YELLOW}" "[Message] Architecture: ${ARCHITECTURE}"

KERNEL=linux

FAMILY=""
if [[ -e /etc/yum ]]; then
  FAMILY=yum
elif [[ -e /etc/apt ]]; then
  FAMILY=apt
else
  print_message "${RED}" "Sorry: The family not supported by this script"
  exit 1
fi
print_message "${YELLOW}" "[Message] Family: ${FAMILY}"


# 2. Setup the node exporter command
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.${KERNEL}-${ARCHITECTURE}.tar.gz
tar -xzf node_exporter-1.8.2.${KERNEL}-${ARCHITECTURE}.tar.gz -C ./ > /dev/null 2>&1
sudo mv ./node_exporter-1.8.2.${KERNEL}-${ARCHITECTURE}/node_exporter /usr/local/bin/
print_message "${YELLOW}" "[Update]: node_exporter command has been setup"

# 3. Create a user for the node exporter service
if id "node_exporter" &>/dev/null; then
  print_message "${BLUE}" "[Info]: User 'node_exporter' already exists"
else
  sudo useradd --no-create-home --shell /usr/sbin/nologin node_exporter
  print_message "${YELLOW}" "[Update]: User 'node_exporter' created"
fi


# 4. Setup node exporter service
NODE_EXPORTER_SERVICE="/usr/lib/systemd/system/node_exporter.service"
sudo tee ${NODE_EXPORTER_SERVICE} > /dev/null <<EOF
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=always
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
print_message "${YELLOW}" "[Update]: Node Exporter service has been setup and started"


# Rubble remove
rm -rf node_exporter-*
print_message "${GREEN}" "[Success] Node Exporter setup completed."
