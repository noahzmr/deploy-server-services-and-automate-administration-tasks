#!/bin/bash
docker_status=$(systemctl is-active docker 2>/dev/null)
setup_log="/home/admnzeumer/openvpn-setup.log"
DOMAIN_NAME="noerkelit.online"
DOMAIN_NAME_UPPERCASE="NOERKELIT.ONLINE"
USERNAME="admnzeumer"
DC_IP="10.0.3.4"
IP_ADDRES=$(ip addr show eth0 | grep -o 'inet [0-9.]*' | awk '{print $2}')
INTERFACE_NAME="eth0"
DEIN_PASSWORT="2quick4U!Hola"

exec >>"$setup_log" 2>&1

output() {
    local component="$1"
    local message="$2"
    local status="$3"

    # Farbcodierung und Emoji je nach Status
    case "$status" in
    "success")
        color="\e[32m"
        emoji="✅"
        ;;
    "error")
        color="\e[31m"
        emoji="❌"
        ;;
    "warning")
        color="\e[33m"
        emoji="❗"
        ;;
    "info")
        color="\e[0m"
        emoji="ℹ️"
        ;;
    "validierung")
        color="\e[95m"
        emoji="✔️"
        ;;
    "complete")
        color="\e[95m"
        emoji="🎉"
        ;;
    "failed")
        color="\e[31m"
        emoji="☠️"
        ;;
    esac

    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local formatted_component="[$component] "
    local formatted_status="[$emoji $status $emoji] "

    # Berechnen der Längen für die Ausrichtung
    local component_length=${#formatted_component}
    local status_length=${#formatted_status}

    # Erstellen der Ausgabe mit der richtigen Ausrichtung
    local output_message="$timestamp $formatted_status$message"
    local padding_length=$((80 - ${#output_message} - component_length - status_length))

    if [ "$padding_length" -gt 0 ]; then
        local padding=" "
        while [ ${#padding} -lt $padding_length ]; do
            padding+=" "
        done
        output_message+=" $formatted_component$color$padding\e[0m"
    else
        output_message+=" $formatted_component$color\e[0m"
    fi

    echo -e "$output_message"
}

install_docker() {
    output "Docker" "Update System" "info"
    sudo apt-get update

    output "Docker" "Install Dependencys" "info"
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    output "Docker" "Curl Docker packages" "info"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update

    output "Docker" "Install Docker" "info"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    output "Docker" "Start and enable Docker" "info"
    sudo systemctl start docker
    sudo systemctl enable docker

    output "Docker" "status: ${docker_status}" "info"

}

install_netdata() {
    output "Netdata" "Pull Netdata Docker-Image" "info"
    sudo docker pull netdata/netdata

    output "Netdata" "Start the Container" "info"
    sudo docker run -d --name=netdata \
        -p 19999:19999 \
        -v /proc:/host/proc:ro \
        -v /sys:/host/sys:ro \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        --cap-add SYS_PTRACE \
        --security-opt apparmor=unconfined \
        --restart unless-stopped \
        netdata/netdata
}

dns_seeting() {
    output "DNS" "Update System and install dependencys" "info"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install resolvconf -y

    output "DNS" "Setze die neuen DNS Server" "info"
    sudo tee /etc/resolvconf/resolv.conf.d/head >/dev/null <<EOL
nameserver $DC_IP
nameserver 8.8.8.8
EOL

    output "DNS" "Update Conf file" "info"
    sudo resolvconf --enable-updates
    sudo resolvconf -u

    output "DNS" "restart" "info"
    sudo systemctl restart resolvconf.service
    sudo systemctl restart systemd-resolved.service

    systemd-resolve --status
}

domain_join() {
    dns_seeting
    hostname=$(hostname)
    output "Domain-Join" "Updatehostname" "info"
    sudo hostnamectl set-hostname $(hostname)

    sudo tee /etc/hosts >/dev/null <<EOL
    127.0.0.1      localhost
    $IP_ADDRES     $(hostname) $(hostname).$DOMAIN_NAME
EOL

    sudo tee /etc/lmhosts >/dev/null <<EOL
    $IP_ADDRES     ${hostname^^}
EOL

    output "Domain-Join" "Install Needed Dependencies" "info"
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install realmd sssd sssd-tools samba-common smbclient krb5-user packagekit samba-common-bin oddjob oddjob-mkhomedir adcli -y

    output "Kerberos-Config" "Configuring Kerberos" "info"
    sudo tee /etc/krb5.conf >/dev/null <<EOL
[logging]
default = FILE:/var/log/krb5libs.log

[libdefaults]
    default_realm = $DOMAIN_NAME_UPPERCASE
    kdc_timesync = 1
    ccache_type = 4
    forwardable = true
    proxiable = true
    ticket_lifetime = 24h
    rdns = false

[realms]
    $DOMAIN_NAME_UPPERCASE = {
        kdc = $DC_IP
        admin_server = $DC_IP
    }

[domain_realm]
    .$DOMAIN_NAME = $DOMAIN_NAME_UPPERCASE
    $DOMAIN_NAME = $DOMAIN_NAME_UPPERCASE
EOL
    output "Kerberos-Config" "Restart Kerberos" "info"
    sudo systemctl restart krb5-user
    output "Domain-Join" "Join the Domain" "info"
    kinit $USERNAME@$DOMAIN_NAME_UPPERCASE
    echo $DEIN_PASSWORT | sudo realm join --user=admnzeumer@DOMAIN_NAME_UPPERCASE dc-01.$DOMAIN_NAME

}

install_docker
install_netdata
domain_join
