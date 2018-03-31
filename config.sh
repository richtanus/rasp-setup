#!/bin/bash

echo -n "Did you modify 'config.sh' file to put in all your setting? [y/N]: "
read answer
if [[ $answer != "y" ]]; then
	echo "Please put in your config first"
	exit 0
fi


EMAIL_IP_DEST="your_dest_gmail" #default all using gmail.com
EMAIL_IP_SOURCE="your_source_gmail"
EMAIL_IP_SOURCE_PWD="your_source_gmail_pwd"



