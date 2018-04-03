#!/bin/bash

echo -n "Did you modify 'config.sh' file to put in all your setting? [y/N]: "
read answer
if [[ $answer != "y" ]]; then
	echo "Please put in your config first"
	exit 0
fi


EMAIL_IP_DEST="your_dest_gmail" #default all using gmail.com, NOT include the domain '@gmail.com'
EMAIL_IP_SOURCE="your_source_gmail"
EMAIL_IP_SOURCE_PWD="your_source_gmail_pwd"

NEW_USER="nancy"
NEW_USER_PWD="111111"

NEW_DB_USER="gavin"
NEW_DB_USER_PWD="111111"

NEW_HOSTNAME="ggdev"

# Home dev folder, place dev code inside
HOME_DEV_FOLDER="dev"


