#!/bin/bash
cd "`dirname \"$0\"`"
SCRIPT_WD=`pwd`
DIR=/Library/Receipts/clicktoflash-nonadmin.pkg/
GROUPS=`id -Gn $USER`

case `uname -r` in
	[89].*)
		true
		;;
	*)
		echo "Running on Snow Leopard or newer, no need to care."
		exit 1
esac

if [ -d $DIR ]; then
	echo "There is a receipt, no admin privs required for installer pkg."
	exit 1
fi

if [ "$GROUPS" == "20" ]; then
	echo "User has admin privs, no admin privs required for installer pkg."
	exit 1
else
	if [[ "$GROUPS" =~ " 20 " ]]; then
		echo "User has admin privs, no admin privs required for installer pkg."
		exit 1
	fi
fi

echo "No receipt, no admin privs, installer must ask for admin password."
exit 0