#!/bin/bash

public_ip="20.218.74.87"
vpn_port="19443"
vpn_protokoll="tcp"
openVpn_netzwork="10.0.5.0 255.255.255.0"
sudo usermod -aG sudo admnzeumer
setup_log="/home/admnzeumer/openvpn-setup.log"
setup_log_2="/home/admnzeumer/clean-openvpn-setup.log"
>"$setup_log"
common_name="openvpn.noerkelit.online"
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

cleanup() {

    systemctl stop openvpn-server@server.service

    fuser -k -n tcp $vpn_port

    rm -rf "/etc/openvpn/" "/home/admnzeumer/pki" "/var/log/openvpn/ipp.txt"

    output "Cleanup" "OpenVPN-Dienst wurde gestoppt. Port $vpn_port wurde freigegeben. Alle neu erstellten Pfade und Dateien wurden gelöscht." "success"
}

set_ntp_server_to_hamburg() {
    sudo timedatectl set-ntp yes
    sudo timedatectl set-timezone Europe/Berlin
    output "NTP" $(timedatectl show --property=NTP) "info"
    output "NTP" $(timedatectl show --property=Timezone) "info"
}

modify_easyrsa_vars() {
    local vars_file="/etc/openvpn/easy-rsa/pki/vars"

    # Ändere den Pfad zur CA-Datei
    sed -i 's/^#set_var EASYRSA_REQ_COUNTRY.*/set_var EASYRSA_REQ_COUNTRY    "DE"/' "$vars_file"

    # Ändere das Ablaufdatum für Zertifikate auf 365 Tage
    sed -i 's/^#set_var EASYRSA_CERT_EXPIRE.*/set_var EASYRSA_CERT_EXPIRE    365/' "$vars_file"

    # Ändere das Ablaufdatum für die CA auf 5 Jahre (1825 Tage)
    sed -i 's/^#set_var EASYRSA_CA_EXPIRE.*/set_var EASYRSA_CA_EXPIRE      1825/' "$vars_file"

    # Aktiviere den Batch-Modus für das automatische Signieren von Zertifikaten
    sed -i 's/^#set_var EASYRSA_BATCH.*/set_var EASYRSA_BATCH          "yes"/' "$vars_file"

    # Setze DN-Variablen
    sed -i 's/^#set_var EASYRSA_REQ_PROVINCE.*/set_var EASYRSA_REQ_PROVINCE   "Hamburg"/' "$vars_file"
    sed -i 's/^#set_var EASYRSA_REQ_CITY.*/set_var EASYRSA_REQ_CITY       "Hamburg"/' "$vars_file"
    sed -i 's/^#set_var EASYRSA_REQ_ORG.*/set_var EASYRSA_REQ_ORG        "noerkelIT"/' "$vars_file"
    sed -i 's/^#set_var EASYRSA_REQ_EMAIL.*/set_var EASYRSA_REQ_EMAIL      "it@noerkel.de"/' "$vars_file"
    sed -i 's/^#set_var EASYRSA_REQ_OU.*/set_var EASYRSA_REQ_OU         "IT"/' "$vars_file"
    sed -i 's/^#set_var EASYRSA_REQ_CN.*/set_var EASYRSA_REQ_CN         "noerkelIT hiknzu"/' "$vars_file"
}

installer() {
    sudo apt-get update
    sudo apt-get install openvpn -y
    sudo apt-get install git -y
}

set_openvpn_default_working_directory() {
    local openvpn_service_file="/etc/systemd/system/openvpn-server@server.service"
    local default_working_directory="/etc/openvpn"

    sed -i 's/^WorkingDirectory=.*/WorkingDirectory=\/etc\/openvpn/' /lib/systemd/system/openvpn-server@.service

    if [ ! -f "$openvpn_service_file" ]; then
        output "OpenVpn-WorkDir" "Die systemd-Serviceeinheit '$openvpn_service_file' existiert nicht." "error"
    fi

    sudo sed -i "s|^WorkingDirectory=.*|WorkingDirectory=$default_working_directory|" "$openvpn_service_file"

    output "OpenVpn-WorkDir" "Arbeitsverzeichnis für den OpenVPN-Dienst auf den Standardpfad '$default_working_directory' gesetzt." "succsess"
}

basic_setup() {
    check_success() {
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            output "OpenVPN-Setup" "Erfolgreich abgeschlossen." "validierung"
        else
            output "OpenVPN-Setup" "Fehler aufgetreten (Exit-Code: $exit_code)." "error"
            return 0
        fi
    }

    if [ ! -f "/etc/openvpn/server.conf" ]; then
        output "OpenVPN-Setup" "OpenVPN wird installiert..."

        installer
        check_success

        output "OpenVPN-Setup" "Klonen von Easy-RSA von GitHub..."
        git clone https://github.com/OpenVPN/easy-rsa.git /etc/openvpn/easy-rsa/
        check_success

        cd /etc/openvpn/easy-rsa/
        output "OpenVPN-Setup" "Initialisiere PKI (Public Key Infrastructure)..."
        sudo /etc/openvpn/easy-rsa/easyrsa3/easyrsa init-pki
        modify_easyrsa_vars
        check_success

        output "OpenVPN-Setup" "Erstelle Certificate Authority (CA)..."
        sudo /etc/openvpn/easy-rsa/easyrsa3/easyrsa build-ca nopass
        check_success

        output "OpenVPN-Setup" "Erstelle Serverzertifikat und Schlüssel..."
        sudo /etc/openvpn/easy-rsa/easyrsa3/easyrsa gen-req server nopass
        sudo /etc/openvpn/easy-rsa/easyrsa3/easyrsa sign-req server server
        check_success

        output "OpenVPN-Setup" "Generiere Diffie-Hellman-Parameter..."
        sudo openssl dhparam -out /etc/openvpn/dh2048.pem 2048
        check_success

        output "OpenVPN-Setup" "Generiere TLS-Authentifizierungsschlüssel..."
        sudo openvpn --genkey --secret /etc/openvpn/ta.key
        check_success

        output "OpenVPN-Setup" "Kopiere Zertifikate und Schlüssel..."
        sudo cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn
        sudo cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn
        sudo cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn
        sudo cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn
        sudo cp /etc/openvpn/ta.key /etc/openvpn
        check_success

        output "OpenVPN-Setup" "Entpacke Server-Konfigurationsdatei..."
        sudo gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf
        check_success

        output "OpenVPN-Setup" "Bearbeite Server-Konfigurationsdatei..."
        update_openVpn_conf
        check_success

        output "OpenVPN-Setup" "Aktiviere IP-Weiterleitung..."
        sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
        sudo sysctl -p
        check_success

        output "OpenVPN-Setup" "Aktiviere und starte OpenVPN-Dienst..."
        sudo systemctl enable openvpn-server@server
        sudo systemctl start openvpn-server@server
        check_success

        output "OpenVPN-Setup" "OpenVPN wurde erfolgreich installiert und konfiguriert."
    else
        output "OpenVPN-Setup" "OpenVPN ist bereits installiert."
    fi
}

update_openVpn_conf() {
    local config_file="/etc/openvpn/server.conf"
    set_openvpn_default_working_directory

    if [ -f "$config_file" ]; then

        cat <<EOL | sudo tee "$config_file"
port $vpn_port
proto  $vpn_protokoll
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
server $openVpn_netzwork
ifconfig-pool-persist /var/log/openvpn/ipp.txt
keepalive 10 120
push "route 10.0.1.0 255.255.255.0"
push "route 10.0.2.0 255.255.255.0"
push "route 10.0.3.0 255.255.255.0"
push "dhcp-option DNS 10.0.3.4"
push "dhcp-option DNS 8.8.4.4"
tls-auth ta.key 0
cipher AES-256-CBC
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
verb 3
EOL
        output "OpenVPN" "OpenVPN-Konfiguration wurde aktualisiert: TCP-Protokoll, Port 19443 und VPN-Netzwerk $openVpn_netzwork." "success"

    else
        output "OpenVPN" "Die OpenVPN-Konfigurationsdatei $config_file existiert nicht." "error"
    fi
}

generate_client_certificates() {
    local client_name="$1"
    local easyrsa_path="/etc/openvpn/easy-rsa/"

    if [ ! -f "$easyrsa_path/pki/issued/$client_name.crt" ] || [ ! -f "$easyrsa_path/pki/private/$client_name.key" ]; then
        sudo /etc/openvpn/easy-rsa/easyrsa3/easyrsa build-client-full "$client_name" nopass
    fi
}

create_client_config() {
    local client_name="$1"
    local client_config_path="/etc/openvpn/client-configs"
    local client_config_file="$client_config_path/$client_name.ovpn"
    generate_client_certificates "$client_name"

    if [ ! -d "$client_config_path" ]; then
        output "Client-Konfiguration" "Das Verzeichnis für die Client-Konfigurationen ($client_config_path) fehlt." "error"
        sudo mkdir -p "$client_config_path"
    fi

    if [ -f "$client_config_file" ]; then
        output "Client-Konfiguration" "Die Client-Konfiguration für $client_name existiert bereits." "warning"
    else
        sudo cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf "$client_config_file"

        cat <<EOL | sudo tee "$client_config_file"
client
dev tun
proto $vpn_protokoll
remote $public_ip $vpn_port
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
tls-auth ta.key 1
cipher AES-256-CBC
verb 3
dev tun
user nobody
group nogroup
remote-cert-tls server
key-direction 1
<ca>
$(cat "/etc/openvpn/ca.crt")
</ca>
<cert>
$(cat "/etc/openvpn/easy-rsa/pki/issued/$client_name.crt")
</cert>
<key>
$(cat "/etc/openvpn/easy-rsa/pki/private/$client_name.key")
</key>
<tls-auth>
$(cat "/etc/openvpn/ta.key") 
</tls-auth>
EOL

        output "Client-Konfiguration" "Die Client-Konfiguration für $client_name wurde erstellt: $client_config_file" "success"
    fi

}

restart_openvpn_service() {
    local action="$1"
    if [ "$action" == "start" ]; then
        sudo systemctl start openvpn-server@server
        output "OpenVPN Service" "Der OpenVPN-Dienst wurde gestartet." "success"
    elif [ "$action" == "restart" ]; then
        sudo systemctl restart openvpn-server@server
        output "OpenVPN Service" "Der OpenVPN-Dienst wurde neu gestartet." "success"
    else
        output "OpenVPN Service" "Ungültige Aktion. Verwenden Sie 'start' oder 'restart'." "error"
    fi
}

check_setup_success() {
    local openvpn_conf="/etc/openvpn/server.conf"
    local client_name="nzeumer"

    if [ ! -f "$openvpn_conf" ]; then
        output "Setup-Prüfung" "OpenVPN-Konfigurationsdatei fehlt: $openvpn_conf" "validierung"
        return 1
    fi

    if ! grep -q "proto tcp" "$openvpn_conf" || ! grep -q "port 19443" "$openvpn_conf" || ! grep -q "server $openVpn_netzwork" "$openvpn_conf"; then
        output "Setup-Prüfung" "Die OpenVPN-Konfiguration wurde nicht vollständig angepasst." "validierung"
        return 1
    fi

    local client_config="/etc/openvpn/client-configs/$client_name.ovpn"
    if [ ! -f "$client_config" ]; then
        output "Setup-Prüfung" "Die Client-Konfiguration für $client_name fehlt: $client_config" "validierung"
        return 1
    fi

    if ! systemctl is-active --quiet openvpn-server@server; then
        output "Setup-Prüfung" "Der OpenVPN-Dienst ist nicht gestartet." "validierung"
        return 1
    fi

    output "Setup-Prüfung" "Das Setup wurde erfolgreich abgeschlossen." "validierung"
    return 0
}

setupt_ufw() {

    output "UFW" "Setup the Firewall..." "Info"

    sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    sudo sysctl -p

    sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

    sudo ufw --force enable
    sudo ufw default allow

    if ! grep -q '10.0.5.0/24' /etc/ufw/before.rules; then
        sudo bash -c 'cat <<EOL >>/etc/ufw/before.rules

# NAT-Regeln für 10.0.5.0/24
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.0.5.0/24 -o eth0 -j MASQUERADE
COMMIT
EOL'
    fi

    sudo ufw status numbered | grep -q '1443/tcp'
    if [ $? -ne 0 ]; then
        output "UFW" "Allow OpenVpn Port..." "Info"

        sudo ufw allow 1443/tcp
    fi

    sudo ufw status numbered | grep -q '22/tcp'
    if [ $? -ne 0 ]; then
        output "UFW" "Allow SSH Port" "Info"
        sudo ufw allow 22/tcp
    fi

    sudo ufw disable
    sudo ufw enable

    output "UFW" $(sudo ufw status) "info"
    sudo iptables -P FORWARD ACCEPT

    if ! sudo iptables -t nat -C POSTROUTING -s 10.0.5.0/24 -o eth0 -j MASQUERADE 2>/dev/null; then
        sudo iptables -t nat -A POSTROUTING -s 10.0.5.0/24 -o eth0 -j MASQUERADE
        output "NAT" "IPTABLES-NAT-Regel hinzugefügt." "info"
    else
        output "NAT" "IPTABLES-NAT-Regel existiert bereits." "info"
    fi
}

install_docker() {
    sudo apt-get update

    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo systemctl start docker
    sudo systemctl enable docker
}
install_netdata() {
    sudo docker pull netdata/netdata

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
set_ntp_server_to_hamburg

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

# cleanup

setupt_ufw

basic_setup

update_openVpn_conf

create_client_config "nzeumer"

restart_openvpn_service "start"
check_setup_success

install_docker
install_netdata

domain_join

if [ $? -eq 0 ]; then
    output "Setup-Prüfung" "Das Setup war erfolgreich. Weitere Aktionen können durchgeführt werden." "complette"
else
    output "Setup-Prüfung" "Das Setup war nicht erfolgreich. Bitte überprüfen Sie die Ausgaben und beheben Sie Probleme." "failed"
fi

grep -v 'TESTING ENCRYPT/DECRYPT of packet' $setup_log >$setup_log_2
exit 0
