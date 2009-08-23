#!/bin/bash
cd "`dirname \"$0\"`"
SCRIPT_WD=`pwd`
DIR=/Library/Receipts/clicktoflash-nonadmin.pkg/
GROUPS=`id -Gn $USER`


# 1 is a successful result, and requires installation with an admin password; if the result is 0, this package is unavailable

rm -rf /tmp/ClickToFlash.webplugin

if [ -d /tmp/ClickToFlash.webplugin ]; then
	echo "we don't have privs to delete the existing temporary file, so we need admin privs to do so."
	exit 1
fi

case `uname -r` in
	[89].*)
		true
		;;
	*)
		echo "Running on Snow Leopard or newer, no need to care."
		exit 0
esac

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