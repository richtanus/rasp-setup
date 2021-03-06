#!/bin/bash

echo -n "Did you modify 'config.sh' file to put in all your setting? [y/N]: "
read answer
if [[ $answer != "y" ]]; then
	echo "Please put in your config first"
	exit 0
fi


EMAIL_IP_DEST="richardtanus" #default all using gmail.com, NOT include the domain '@gmail.com'
EMAIL_IP_SOURCE="latom76"
EMAIL_IP_SOURCE_PWD="aaaa1111"

NEW_USER="gavin"
NEW_USER_PWD="gavin22"

NEW_DB_ROOT_PWD="gavin22"
NEW_DB_USER="gavin"
NEW_DB_USER_PWD="gavin22"

NEW_HOSTNAME="ggdev"

# Home dev folder, place dev code inside
HOME_DEV_FOLDER="dev"


raspap_dir="/etc/raspap"
raspap_user="www-data"
version=`sed 's/\..*//' /etc/debian_version`

# Determine version, set default home location for lighttpd and 
# php package to install 
webroot_dir="/var/www/raspap" 
if [ $version -eq 9 ]; then 
    version_msg="Raspian 9.0 (Stretch)" 
    php_package="php7.0-cgi" 
elif [ $version -eq 8 ]; then 
    version_msg="Raspian 8.0 (Jessie)" 
    php_package="php5-cgi" 
else 
    version_msg="Raspian earlier than 8.0 (Wheezy)"
    webroot_dir="/var/www" 
    php_package="php5-cgi" 
fi 
