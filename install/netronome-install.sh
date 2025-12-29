#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Sukoshi1507o
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/autobrr/netronome

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installation des dépendances"
$STD apt-get install -y \
    curl \
    wget \
    sudo \
    mc \
    iperf3 \
    traceroute \
    mtr-tiny
msg_ok "Dépendances installées"

msg_info "Installation de Netronome"
RELEASE=$(curl -s https://api.github.com/repos/autobrr/netronome/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
wget -q https://github.com/autobrr/netronome/releases/download/v${RELEASE}/netronome_${RELEASE}_linux_x86_64.tar.gz
tar -xzf netronome_${RELEASE}_linux_x86_64.tar.gz -C /usr/local/bin
chmod +x /usr/local/bin/netronome
rm netronome_${RELEASE}_linux_x86_64.tar.gz
msg_ok "Netronome v${RELEASE} installé"

msg_info "Création de l'utilisateur netronome"
useradd -r -s /bin/false -d /opt/netronome netronome
mkdir -p /opt/netronome/{data,config}
chown -R netronome:netronome /opt/netronome
msg_ok "Utilisateur netronome créé"

msg_info "Génération de la configuration"
cat > /opt/netronome/config/config.toml << 'EOF'
[server]
host = "0.0.0.0"
port = 7575

[database]
type = "sqlite"
path = "/opt/netronome/data/netronome.db"

[log]
level = "info"

[speedtest]
timeout = 30

[packetloss]
enabled = true
EOF
chown netronome:netronome /opt/netronome/config/config.toml
msg_ok "Configuration générée"

msg_info "Création du service systemd"
cat > /etc/systemd/system/netronome.service << 'EOF'
[Unit]
Description=Netronome Network Monitoring
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=netronome
Group=netronome
WorkingDirectory=/opt/netronome
ExecStart=/usr/local/bin/netronome serve --config=/opt/netronome/config/config.toml
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=netronome

# Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/netronome/data
AmbientCapabilities=CAP_NET_RAW

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q --now netronome.service
msg_ok "Service systemd créé et démarré"

msg_info "Installation de LibreSpeed CLI (optionnel)"
if command -v go &> /dev/null; then
    GOBIN=/usr/local/bin go install github.com/librespeed/speedtest-cli/cmd/librespeed-cli@latest
    msg_ok "LibreSpeed CLI installé"
else
    msg_info "Go non disponible, installation de LibreSpeed CLI ignorée"
fi

motd_ssh
customize

msg_info "Nettoyage"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Nettoyage effectué"
