#!/bin/bash


source config.sh


function install_sendip() {
    # replace variable fron config.sh
    install_log "Setting up sendip"
    cat conf/sendip.py | sed s/\\[destination\\]/${EMAIL_IP_DEST}/g | sed s/\\[source\\]/${EMAIL_IP_SOURCE}/g | sed s/\\[source_email_password\\]/${EMAIL_IP_SOURCE_PWD}/g | tee /home/pi/sendip.py
}


function update_hostname() {
    install_log "Updating hostname"
    sudo sed -i "s/raspberrypi/${NEW_HOSTNAME}/g" /etc/hostname
    sudo sed -i "s/raspberrypi/${NEW_HOSTNAME}/g" /etc/hosts
}

 
function update_system_packages() {
    install_log "Updating sources"
    sudo apt-get update || install_error "Unable to update package list"
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

# Move configuration file to the correct location
function move_config_file() {
    if [ ! -d "$raspap_dir" ]; then
        install_error "'$raspap_dir' directory doesn't exist"
    fi

    install_log "Moving configuration file to '$raspap_dir'"
    sudo mv "$webroot_dir"/raspap.php "$raspap_dir" || install_error "Unable to move files to '$raspap_dir'"
    sudo chown -R $raspap_user:$raspap_user "$raspap_dir" || install_error "Unable to change file ownership for '$raspap_dir'"
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

# Generate logging enable/disable files for hostapd
function create_logging_scripts() {
    install_log "Creating logging scripts"
    sudo mkdir $raspap_dir/hostapd || install_error "Unable to create directory '$raspap_dir/hostapd'"

    # Move existing shell scripts 
    sudo mv $webroot_dir/installers/*log.sh $raspap_dir/hostapd || install_error "Unable to move logging scripts"
}

# Adds www-data user to the sudoers file with restrictions on what the user can execute
function patch_system_files() {
    # add symlink to prevent wpa_cli cmds from breaking with multiple wlan interfaces
    install_log "symlinked wpa_supplicant hooks for multiple wlan interfaces"
    sudo ln -s /usr/share/dhcpcd/hooks/10-wpa_supplicant /etc/dhcp/dhclient-enter-hooks.d/
    # Set commands array
    cmds=(
        "/sbin/ifdown"
        "/sbin/ifup"
        "/bin/cat /etc/wpa_supplicant/wpa_supplicant.conf"
        "/bin/cat /etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
        "/bin/cat /etc/wpa_supplicant/wpa_supplicant-wlan1.conf"
        "/bin/cp /tmp/wifidata /etc/wpa_supplicant/wpa_supplicant.conf"
        "/bin/cp /tmp/wifidata /etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
        "/bin/cp /tmp/wifidata /etc/wpa_supplicant/wpa_supplicant-wlan1.conf"
        "/sbin/wpa_cli scan_results"
        "/sbin/wpa_cli scan"
        "/sbin/wpa_cli reconfigure"
        "/bin/cp /tmp/hostapddata /etc/hostapd/hostapd.conf"
        "/etc/init.d/hostapd start"
        "/etc/init.d/hostapd stop"
        "/etc/init.d/dnsmasq start"
        "/etc/init.d/dnsmasq stop"
        "/bin/cp /tmp/dhcpddata /etc/dnsmasq.conf"
        "/sbin/shutdown -h now"
        "/sbin/reboot"
        "/sbin/ip link set wlan0 down"
        "/sbin/ip link set wlan0 up"
        "/sbin/ip -s a f label wlan0"
        "/sbin/ip link set wlan1 down"
        "/sbin/ip link set wlan1 up"
        "/sbin/ip -s a f label wlan1"
        "/bin/cp /etc/raspap/networking/dhcpcd.conf /etc/dhcpcd.conf"
        "/etc/raspap/hostapd/enablelog.sh"
        "/etc/raspap/hostapd/disablelog.sh"
    )

    # Check if sudoers needs patching
    if [ $(sudo grep -c www-data /etc/sudoers) -ne 28 ]
    then
        # Sudoers file has incorrect number of commands. Wiping them out.
        install_log "Cleaning sudoers file"
        sudo sed -i '/www-data/d' /etc/sudoers
        install_log "Patching system sudoers file"
        # patch /etc/sudoers file
        for cmd in "${cmds[@]}"
        do
            sudo_add $cmd
            IFS=$'\n'
        done
    else
        install_log "Sudoers file already patched"
    fi
}

function sudo_add() {
    sudo bash -c "echo \"www-data ALL=(ALL) NOPASSWD:$1\" | (EDITOR=\"tee -a\" visudo)" \
        || install_error "Unable to patch /etc/sudoers"
}

function install_dependencies() {
    install_log "Installing required packages"
    #sudo apt-get install lighttpd $php_package git hostapd dnsmasq || install_error "Unable to install dependencies"
    sudo apt-get install apache2 php7.0 php7.0-cgi libapache2-mod-php7.0 mysql-server mysql-client phpmyadmin samba git hostapd dnsmasq || install_error "Unable to install dependencies"
}


function add_user() {
    install_log "adding user account ${NEW_USER}"
    sudo adduser --disabled-password --gecos "" ${NEW_USER}
    echo ${NEW_USER}:${NEW_USER_PWD} | sudo chpasswd
    sudo adduser ${NEW_USER} sudo
    
    #delete user
    #sudo userdel -r ${NEW_USER}

    mkdir /home/${NEW_USER}/${HOME_DEV_FOLDER}
    chown ${NEW_USER} /home/${NEW_USER}/${HOME_DEV_FOLDER}
    chgrp ${NEW_USER} /home/${NEW_USER}/${HOME_DEV_FOLDER}
}

function setup_samba_user() {
    install_log "Setuping up samba password"
    echo -ne "${NEW_USER_PWD}\n${NEW_USER_PWD}\n" | sudo smbpasswd -a ${NEW_USER}
}

function setup_mysql_access() {
    install_log "setuping mysql access"
    sudo mysqladmin --user=root password "${NEW_DB_ROOT_PWD}"
    sudo mysql -uroot -p${NEW_DB_ROOT_PWD} -e "CREATE USER '${NEW_DB_USER}'@'localhost' IDENTIFIED BY '${NEW_DB_USER_PWD}';"
    sudo mysql -uroot -p${NEW_DB_ROOT_PWD} -e "CREATE USER '${NEW_DB_USER}'@'%' IDENTIFIED BY '${NEW_DB_USER_PWD}';"
    sudo mysql -uroot -p${NEW_DB_ROOT_PWD} -e "GRANT ALL PRIVILEGES ON *.* TO '${NEW_DB_USER}'@'localhost' REQUIRE NONE WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"
    sudo mysql -uroot -p${NEW_DB_ROOT_PWD} -e "GRANT ALL PRIVILEGES ON *.* TO '${NEW_DB_USER}'@'%' REQUIRE NONE WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"
    sudo mysql -uroot -p${NEW_DB_ROOT_PWD} -e "FLUSH PRIVILEGES;"
    #need to allow access from other ip
    sudo sed -i "s/127\.0\.0\.1/0\.0\.0\.0/g" /etc/mysql/mariadb.conf.d/50-server.cnf
    sudo service mysql restart
}

function setup_apache_vhost() {
    install_log "setuping apache vhost"
    # setup my project 
    git clone https://github.com/gavinttla/ymxads /tmp/ymxads || install_error "Unable to download files from github"
    sudo mv /tmp/ymxads /home/${NEW_USER}/${HOME_DEV_FOLDER}/
    chown -R ${NEW_USER} /home/${NEW_USER}/${HOME_DEV_FOLDER}/ymxads
    chgrp -R ${NEW_USER} /home/${NEW_USER}/${HOME_DEV_FOLDER}/ymxads
    chmod 777 -R /home/${NEW_USER}/${HOME_DEV_FOLDER}/ymxads/storage
    chmod 777 -R /home/${NEW_USER}/${HOME_DEV_FOLDER}/ymxads/bootstrap/cache
    ln -s /home/${NEW_USER}/${HOME_DEV_FOLDER}/ymxads /var/www/ymxads

    sudo cp conf/vhost.conf /etc/apache2/sites-available/
    sudo a2ensite vhost
    sudo a2enmod rewrite
    sudo service apache2 restart
}


function setup_laravel_project() {
    install_log "setuping apache vhost"
}

function next_step() {
    echo -n "Please ocnfirm to go to next step [y/n]: "
    read answer
    if [[ $answer != "y" ]]; then
        echo "start with next step."
    fi
}


function install_raspap() {
    next_step
    update_system_packages
    next_step
    install_dependencies
    next_step
    create_raspap_directories
    next_step
    check_for_old_configs
    next_step
    download_latest_files
    next_step
    change_file_ownership
    next_step
    create_logging_scripts
    next_step
    move_config_file
    next_step
    install_sendip
    next_step
    default_configuration
    next_step
    patch_system_files
    next_step
    add_user
    next_step
    setup_samba_user
    next_step
    setup_mysql_access
    next_step
    setup_apache_vhost
    next_step
    update_hostname
}

install_raspap
