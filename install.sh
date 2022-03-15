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
install_user=${SUDO_USER:-$USER}

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
    echo -e "\e[39mInstalling and ensuring your system is up to date"
    apt-get -qq update -y || { echo "Could not successfully run apt update"; exit 1; }
    apt-get -qq upgrade -y || { echo "Could not successfully run apt upgrade"; exit 1; }
    echo -e "\e[39mProceeding with installation dependencies..."
    case "$(/usr/bin/lsb_release -si)" in
        Ubuntu) installDocker "Ubuntu" ;;
        Debian) installDocker "Debian" ;;
        *) echo 'You are using an unsupported operating system. Please check the guide for a suitable OS.'; exit ;;
    esac
}

function installDocker() {
    case "$1" in
        Ubuntu)
          OS=ubuntu
          apt_packages="apt-transport-https ca-certificates curl software-properties-common jq"
          ;;
        Debian)
          OS=debian
          apt_packages="sudo apt-transport-https ca-certificates curl gnupg lsb-release jq"
          ;;
        *)
          echo 'You are using an unsupported operating system. Please check the guide for a suitable OS.'; exit 1
          ;;
    esac

    # shellcheck disable=SC2086
    apt-get install $apt_packages -y
    if [[ $(which docker) && $(docker --version) ]]; then
        echo -e "\e[39mDocker Installed, Skipping..."
    else
        echo -e "\e[32mInstalling Docker for ${OS^u}"
        echo -e "\e[39mPlease be patient"
        curl -fsSL "https://download.docker.com/linux/$OS/gpg" | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg --yes
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update -y
        apt-get install docker-ce docker-ce-cli containerd.io -y
        echo -e "\e[39mDocker Installed"
        usermod -aG docker "$install_user"
    fi
    dockerCompose
}

function dockerCompose() {
    dockerComposeV1="https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)"
    dockerComposeV2="$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r ".assets[] | select(.name | contains(\"sha256\") | not) | select(.name | test(\"docker-compose-linux-x86_64\")) | .browser_download_url")"
    if [[ $(which docker-compose) ]]; then
        echo -e "\e[39mDocker-Compose installed, Skipping..."
    else
        echo -e "\e[39mInstalling docker-compose v1"
        curl -L "$dockerComposeV1" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo -e "\e[39mInstalling docker-compose v2"
        mkdir -p /usr/local/lib/docker/cli-plugins
        curl -SL "$dockerComposeV2" -o /usr/local/lib/docker/cli-plugins/docker-compose
        chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
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
    echo "docker run -it --network=sudobox_private -v /opt/sudobox/configs:/configs --rm --name sb-cli ghcr.io/sudobox-io/sb-cli && clear" | tee /usr/local/bin/{sudobox,sb} &>/dev/null
    chmod a+x /usr/local/bin/{sudobox,sb}
    docker pull ghcr.io/sudobox-io/sb-cli
}

function installsbbackend() {
    cd /opt/sudobox/compose || { echo "Could not change directory to /opt/sudobox/compose"; exit 1; }
    grep -w avx /proc/cpuinfo &>/dev/null
    if [ $? -eq 1 ]; then
        echo -e "\e[32mCPU does not support AVX, installing MongoDB V4"
        mongodb_version=4.4.13
    else
        echo -e "\e[32mCPU supports AVX, installing MongoDB V5"
        mongodb_version=latest
    fi
    echo "version: \"3.5\"
services:
  sb_backend:
    image: ghcr.io/sudobox-io/sb-backend
    container_name: sb-backend
    volumes:
      - \"/var/run/docker.sock:/var/run/docker.sock\"
      - \"/opt/sudobox/appdata:/appdata\"
      - \"/opt/sudobox/configs:/configs\"
      - \"/opt/sudobox/compose:/compose\"
      - \"/root/.docker:/root/.docker\"
    networks:
      - sudobox_private
    depends_on:
      - sb_database

  sb_database:
    image: mongo:$mongodb_version
    container_name: sb-database
    volumes:
      - \"/opt/sudobox/appdata/sbdb:/data/db\"
    networks:
      - sudobox_private

networks:
  sudobox_private:
    driver: bridge
    name: sudobox_private" >sb-backend.yml || { echo "Could not create SudoBox backend compose file"; exit 1; }
    echo -e "\e[39mCreated SudoBox backend compose file"
    docker-compose -f sb-backend.yml pull && docker-compose -f sb-backend.yml up -d && echo "Created SudoBox backend Container"
}

checkIfSudo
