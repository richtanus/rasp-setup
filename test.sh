#!/bin/bash


source config.sh

function install_log() {
    echo -e "\033[1;32mRaspAP Install: $*\033[m"
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
    sudo apt-get install apache2 php7.0 php7.0-cgi mysql-server mysql-client phpmyadmin samba git hostapd dnsmasq || install_error "Unable to install dependencies"
}


function setup_mysql() {
	sudo sed -i "s/127\.0\.0\.1/0\.0\.0\.0/g" /etc/mysql/mariadb.conf.d/50-server.cnf
}

function update_hostname() {
    install_log "Updating hostname"
    sudo sed -i "s/raspberrypi/${NEW_HOSTNAME}/g" /etc/hostname
    sudo sed -i "s/raspberrypi/${NEW_HOSTNAME}/g" /etc/hosts
}

update_hostname


