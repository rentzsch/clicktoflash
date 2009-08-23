#!/bin/bash
cd "`dirname \"$0\"`"
SCRIPT_WD=`pwd`
DIR=/Library/Receipts/clicktoflash-nonadmin.pkg/
GROUPS=`id -Gn $USER`

if [ -d $DIR ]; then
	echo "There is a receipt, no admin privs required for installer pkg."
	exit 0
fi

if [ "$GROUPS" == "20" ]; then
	echo "User has admin privs, no admin privs required for installer pkg."
	exit 0
else
	if [[ "$GROUPS" =~ " 20 " ]]; then
		echo "User has admin privs, no admin privs required for installer pkg."
		exit 0
	fi
fi

echo "No receipt, no admin privs, installer must ask for admin password."
exit 1