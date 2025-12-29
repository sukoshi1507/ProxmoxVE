#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Sukoshi1507
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/autobrr/netronome

# App Default Values
APP="Netronome"
var_tags="network;monitoring"
var_cpu="2"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    
    if [[ ! -f /usr/local/bin/netronome ]]; then
        msg_error "Netronome n'est pas installé"
        exit
    fi
    
    msg_info "Arrêt de Netronome"
    systemctl stop netronome
    msg_ok "Netronome arrêté"

    msg_info "Mise à jour de Netronome"
    RELEASE=$(curl -s https://api.github.com/repos/autobrr/netronome/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
    wget -q https://github.com/autobrr/netronome/releases/download/v${RELEASE}/netronome_${RELEASE}_linux_x86_64.tar.gz
    tar -xzf netronome_${RELEASE}_linux_x86_64.tar.gz -C /usr/local/bin
    rm netronome_${RELEASE}_linux_x86_64.tar.gz
    msg_ok "Netronome mis à jour vers v${RELEASE}"

    msg_info "Démarrage de Netronome"
    systemctl start netronome
    msg_ok "Netronome démarré"
    msg_ok "Mise à jour terminée"
    exit
}

start
build_container
description

msg_ok "Terminé"
