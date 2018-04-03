#!/bin/bash


source config.sh


function install_sendip() {
    # replace variable fron config.sh
    cat conf/sendip.py | sed s/\\[destination\\]/${EMAIL_IP_DEST}/g | sed s/\\[source\\]/${EMAIL_IP_SOURCE}/g | sed s/\\[source_email_password\\]/${EMAIL_IP_SOURCE_PWD}/g | tee sendip.py
}


function update_hostname() {
	
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



# Verifies existence and permissions of RaspAP directory
function create_raspap_directories() {
    install_log "Creating RaspAP directories"
    if [ -d "$raspap_dir" ]; then
        sudo mv $raspap_dir "$raspap_dir.`date +%F-%R`" || install_error "Unable to move old '$raspap_dir' out of the way"
    fi
    sudo mkdir -p "$raspap_dir" || install_error "Unable to create directory '$raspap_dir'"

    # Create a directory for existing file backups.
    sudo mkdir -p "$raspap_dir/backups"

    # Create a directory to store networking configs
    sudo mkdir -p "$raspap_dir/networking"
    # Copy existing dhcpcd.conf to use as base config
    cat /etc/dhcpcd.conf | sudo tee -a /etc/raspap/networking/defaults

    sudo chown -R $raspap_user:$raspap_user "$raspap_dir" || install_error "Unable to change file ownership for '$raspap_dir'"
}


# Check for existing /etc/network/interfaces and /etc/hostapd/hostapd.conf files
function check_for_old_configs() {
    if [ -f /etc/network/interfaces ]; then
        sudo cp /etc/network/interfaces "$raspap_dir/backups/interfaces.`date +%F-%R`"
        sudo ln -sf "$raspap_dir/backups/interfaces.`date +%F-%R`" "$raspap_dir/backups/interfaces"
    fi

    if [ -f /etc/hostapd/hostapd.conf ]; then
        sudo cp /etc/hostapd/hostapd.conf "$raspap_dir/backups/hostapd.conf.`date +%F-%R`"
        sudo ln -sf "$raspap_dir/backups/hostapd.conf.`date +%F-%R`" "$raspap_dir/backups/hostapd.conf"
    fi

    if [ -f /etc/dnsmasq.conf ]; then
        sudo cp /etc/dnsmasq.conf "$raspap_dir/backups/dnsmasq.conf.`date +%F-%R`"
        sudo ln -sf "$raspap_dir/backups/dnsmasq.conf.`date +%F-%R`" "$raspap_dir/backups/dnsmasq.conf"
    fi

    if [ -f /etc/dhcpcd.conf ]; then
        sudo cp /etc/dhcpcd.conf "$raspap_dir/backups/dhcpcd.conf.`date +%F-%R`"
        sudo ln -sf "$raspap_dir/backups/dhcpcd.conf.`date +%F-%R`" "$raspap_dir/backups/dhcpcd.conf"
    fi

    if [ -f /etc/rc.local ]; then
        sudo cp /etc/rc.local "$raspap_dir/backups/rc.local.`date +%F-%R`"
        sudo ln -sf "$raspap_dir/backups/rc.local.`date +%F-%R`" "$raspap_dir/backups/rc.local"
    fi
}

# Fetches latest files from github to webroot
function download_latest_files() {
    if [ -d "$webroot_dir" ]; then
        sudo mv $webroot_dir "$webroot_dir.`date +%F-%R`" || install_error "Unable to remove old webroot directory"
    fi

    install_log "Cloning latest files from github"
    git clone https://github.com/richtanus/raspap-webgui /tmp/raspap-webgui || install_error "Unable to download files from github"
    sudo mv /tmp/raspap-webgui $webroot_dir || install_error "Unable to move raspap-webgui to web root"
}


# Sets files ownership in web root directory
function change_file_ownership() {
    if [ ! -d "$webroot_dir" ]; then
        install_log "Web root directory doesn't exist, and will try to create one"
	sudo mkdir -p "$webroot_dir"
    fi

    if [ ! -d "$webroot_dir" ]; then
        install_log "Web root directory doesn't exist, and will try to create one"
    fi

    install_log "Changing file ownership in web root directory"
    sudo chown -R $raspap_user:$raspap_user "$webroot_dir" || install_error "Unable to change file ownership for '$webroot_dir'"
}


function add_user() {
    sudo adduser --disabled-password --gecos "" ${NEW_USER}
    echo ${NEW_USER}:${NEW_USER_PWD} | sudo chpasswd
    sudo adduser ${NEW_USER} sudo
    
    #delete user
    #sudo userdel -r ${NEW_USER}
}


function setup_dev_folder() {
    mkdir /home/${NEW_USER}/${HOME_DEV_FOLDER}
    chown ${NEW_USER} /home/${NEW_USER}/${HOME_DEV_FOLDER}
    chgrp ${NEW_USER} /home/${NEW_USER}/${HOME_DEV_FOLDER}
}


function install_dependencies() {
    install_log "Installing required packages"
    #sudo apt-get install lighttpd $php_package git hostapd dnsmasq || install_error "Unable to install dependencies"
    sudo apt-get install apache2 php7.0 php7.0-cgi libapache2-mod-php7.0 mysql-server mysql-client phpmyadmin samba git hostapd dnsmasq || install_error "Unable to install dependencies"
}

function setup_samba_user() {
    echo -ne "${NEW_USER_PWD}\n${NEW_USER_PWD}\n" | sudo smbpasswd -a ${NEW_USER}
}


create_raspap_directories
