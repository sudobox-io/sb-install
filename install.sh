#!/bin/bash
#########################################################################
# Title:         SudoBox: Install Script                                #
# Author(s):     demondamz, Xarritomi, Xpl0yt91, hawkinzzz, salty       #
# URL:           https://github.com/sudobox-io/sb-install               #
# --                                                                    #
#########################################################################
#                   GNU General Public License v3.0                     #
#########################################################################

clear
function installation() {
    echo -e "\e[36m--------------- Sudobox Installer ---------------"
    echo "  Pre Installer for SudoBox.io "
    echo "  Version 0.0.1 "
    echo "  All documentation can be found at https://docs.sudobox.io"
    echo ""
    echo -e "  \e[33mTasks :"
    echo "     - Create SudoBox installation directories at /opt/sudobox"
    echo "     - Install Docker & Docker-Compose"
    echo "     - Create Docker Networks: sudobox & sudobox_private"
    echo "     - Install the SudoBox CLI, Backend & Database Containers"
    echo ""
    echo "     This script will run automatically in 10 seconds. Please exit if you wish to abort!"
    echo ""
    echo ""
    
    #     read n
    #     case $n in
    #     y) checkIfSudo ;;
    #     e) exit ;;
    #     *) echo -e "\e[91mInvalid Option" ;;
    sleep 10
    checkIfSudo
}

function checkIfSudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "\e[91mError, Please run as root, exiting...."
        exit
    else
        echo -e "\e[32mProceeding with the Pre Installation..."
        createdir
        downloadDependencies
        dockernetworkcheckpublic
        installsbbackend
        installsbcli
        echo ""
        echo ""
        echo "Finished installing all Dependencies, Moving to CLI Questions..."
        echo -e "\e[1mYou can run SudoBox CLI at anytime using 'sb' or 'sudobox'"
        echo ""
    fi
    
}

function downloadDependencies() {
    echo -e "\e[39mInstalling and ensuring your system is upto date"
    sudo apt-get -qq update -y || { echo "Could not successfully run apt update"; exit 1; }
    sudo apt-get -qq upgrade -y || { echo "Could not successfully run apt upgrade"; exit 1; }
    echo -e "\e[39mProceeding with installation dependencies..."
    
    if [[ $(which docker) && $(docker --version) ]]; then
        echo -e "\e[39mDocker Installed, Skipping..."
    else
        echo -e "\e[39mInstalling Docker"
        sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
        sudo apt install docker-ce -y
        sudo groupadd docker
        sudo usermod -aG docker "$USER"
        newgrp docker
    fi
    
    if [[ $(which docker-compose) ]]; then
        echo -e "\e[39mDocker-Compose installed, Skipping..."
    else
        echo -e "\e[39mInstalling docker-compose"
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
}

function createdir() {
    mkdir -p /opt/sudobox/{configs,appdata,compose} || { echo "Could not create sudobox directories"; exit 1; }
    touch /opt/sudobox/configs/cli-settings.yml || { echo "Could create sudobox CLI config file"; exit 1; }
    echo -e "\e[39mCreated SudoBox Directories"
}

function dockernetworkcheckpublic() {
    sudobox_network_exists=$(docker network ls | grep -w sudobox)
    if [[ "$sudobox_network_exists" ]]; then
        echo -e "\e[39mDocker Network ( sudobox )Exists, Skipping..."
    else
        echo -e "\e[39mCreating Docker Network sudobox"
        docker network create sudobox || { echo "Could not create sudobox Docker Network"; exit 1; }
        echo -e "\e[39mCreated Docker Network sudobox"
    fi
}

function installsbcli() {
    echo "docker run -it --network=sudobox_private -v /opt/sudobox/configs:/configs --rm --name sb-cli ghcr.io/sudobox-io/sb-cli && clear" >> /usr/local/bin/sudobox
    sudo chmod a+x /usr/local/bin/sudobox
    echo "docker run -it --network=sudobox_private -v /opt/sudobox/configs:/configs --rm --name sb-cli ghcr.io/sudobox-io/sb-cli && clear" >> /usr/local/bin/sb
    sudo chmod a+x /usr/local/bin/sb
}

function installsbbackend() {
    cd /opt/sudobox/compose || { echo "Could not change directory to /opt/sudobox/compose"; exit 1; }
    echo 'version: "3.5"
services:
  sb_backend:
    image: ghcr.io/sudobox-io/sb-backend
    container_name: sb-backend
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "/opt/sudobox/appdata:/appdata"
      - "/opt/sudobox/configs:/configs"
      - "/opt/sudobox/compose:/compose"
      - "/root/.docker:/root/.docker"
    networks:
      - sudobox_private
    depends_on:
      - sb_database

  sb_database:
    image: mongo:latest
    container_name: sb-database
    volumes:
      - "/opt/sudobox/appdata/sbdb:/data/db"
    networks:
      - sudobox_private

networks:
  sudobox_private:
    driver: bridge
    name: sudobox_private' >sb-backend.yml || { echo "Could not create SudoBox backend compose file"; exit 1; }
    echo -e "\e[39mCreated SudoBox backend compose file"
    docker-compose pull && docker-compose -f sb-backend.yml up -d && echo "Created SudoBox backend Container"
}

installation
