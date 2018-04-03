#!/bin/bash


source config.sh


function install_sendip() {
    # replace variable fron config.sh
    cat conf/sendip.py | sed s/\\[destination\\]/${EMAIL_IP_DEST}/g | sed s/\\[source\\]/${EMAIL_IP_SOURCE}/g | sed s/\\[source_email_password\\]/${EMAIL_IP_SOURCE_PWD}/g | tee sendip.py
}


function update_hostname() {
	
}


function add_user() {
    adduser ${NEW_USER}
}


# Set up default configuration
function default_configuration() {
    install_log "Setting up hostapd"
    if [ -f /etc/default/hostapd ]; then
        sudo mv /etc/default/hostapd /tmp/default_hostapd.old || install_error "Unable to remove old /etc/default/hostapd file"
    fi
    sudo mv $webroot_dir/config/default_hostapd /etc/default/hostapd || install_error "Unable to move hostapd defaults file"
    sudo mv $webroot_dir/config/hostapd.conf /etc/hostapd/hostapd.conf || install_error "Unable to move hostapd configuration file"
    sudo mv $webroot_dir/config/dnsmasq.conf /etc/dnsmasq.conf || install_error "Unable to move dnsmasq configuration file"
    sudo mv $webroot_dir/config/dhcpcd.conf /etc/dhcpcd.conf || install_error "Unable to move dhcpcd configuration file"

    # Generate required lines for Rasp AP to place into rc.local file.
    # #RASPAP is for removal script
    lines=(
    'echo 1 > \/proc\/sys\/net\/ipv4\/ip_forward #RASPAP'
    'iptables -t nat -A POSTROUTING -j MASQUERADE #RASPAP'
    '\/usr\/bin\/python \/home\/pi\/sendip\.py & #SENDIP'
    )
    
    for line in "${lines[@]}"; do
        if grep "$line" /etc/rc.local > /dev/null; then
            echo "$line: Line already added"
        else
            sudo sed -i "s/^exit 0$/$line\nexit 0/" /etc/rc.local
            echo "Adding line $line"
        fi
    done
}




