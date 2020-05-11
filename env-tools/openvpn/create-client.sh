#!/bin/bash

# wrapper script to create client keys and package them up with a conf
# file suitable for distribution to end user

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

# check if this client package already exists
if grep -q "CN=$username/" $EASY_RSA/keys/index.txt
then
  echo "keys for user $username have already been built" >&2
  exit 1
fi

echo "building key and conf package for $username"

. ./vars

# create the certificate
"$EASY_RSA/pkitool" --batch  $username

# create a tempdir and gather the files
TMPDIR=$(mktemp -d -p /root) || exit 1
cp $EASY_RSA/keys/$username.{crt,key} $TMPDIR
cp $EASY_RSA/keys/ca.crt $TMPDIR
# put the right names in the conf file so it's all ready for the client.
sed -e "s/SNOWFLAKE/$username/" /etc/openvpn/client.conf.template >$TMPDIR/client.ovpn

cd $TMPDIR
# zip -l to set windows line endings on files
# windows client works with config file having unix line endings, but
# config file is hard to read.
zip -l ~/${username}-openvpn.zip *
cd -

adduser $username -M -n
RPASS=$(mkpasswd -l 10 -c 2 -d 2 -C 2 -s 1)
echo "$username:$RPASS" | chpasswd

# yeah I know I should trap on exit to delete this directory. Lazy.
rm -rf $TMPDIR

echo "~/${username}-openvpn.zip ready for distribution"
echo "$username Password is $RPASS"

