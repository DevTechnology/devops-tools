#!/bin/bash

# wrapper script to delete client keys and machine user account

if [ $UID -ne 0 ]
then
  echo "must be run as root" >&2
  exit 1
fi

if [ -z $1 ]
then
  echo "must supply a username for only argument" >&2
  exit 1
fi

username=$1

export EASY_RSA=/etc/openvpn/easy-rsa

cd $EASY_RSA

# check if this user  exists
if ! grep -q "CN=$username/" $EASY_RSA/keys/index.txt
then
  echo "keys for user $username were not found, wrong name?" >&2
  exit 1
fi

echo "removing keys for $username"
sed -i "/CN=$username/d" $EASY_RSA/keys/index.txt
rm $EASY_RSA/keys/$username.{crt,key}

echo "removing machine account for $username"
userdel $username

echo "removing previous zip for $username"
rm ~/${username}-openvpn.zip 

# yeah I know I should trap on exit to delete this directory. Lazy.
rm -rf $TMPDIR

echo "${username} deleted"
