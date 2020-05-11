#!/bin/bash  
#############
# Generates an RSA 2 2048bit (default) SSH Key, with a random PWD.
# Then uploads the key to the specified AWS IAM user.
#
# usage: addsshkey -un iam_user_name [-s]
#############

IS_SILENT=false
IAM_USERNAME=""

function usage
{
    echo "usage: addsshkey -un iam_user_name [-s]"
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi
while [ "$1" != "" ]; do
    case $1 in
        -s | --silent )         shift
                                IS_SILENT=true
                                ;;
        -un | --user-name )     shift
                                IAM_USERNAME=$1
                                ;;								
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

#If email change to a UserName only
OIFS=$IFS;
IFS="@";
USERNAME_RSA=($IAM_USERNAME);
IFS=$OIFS;

rm jsonoutput.codecommit.*;

KEYLIST=(aws iam list-ssh-public-keys --user-name $IAM_USERNAME)
if "${KEYLIST[@]}" > jsonoutput.codecommit.keylist 2> error.codecommit.keylist; then
   KEYIDS=($(cat jsonoutput.codecommit.keylist | jq -r '.SSHPublicKeys[] | .SSHPublicKeyId'))
   if [[ -n "$KEYIDS" ]]; then
		if [[ ${#KEYIDS[@]} -ge 5 ]]; then
			echo "You have 5 SSH keys already, AWS only takes 5 SSH keys. Delete 1 or more SSH keys"
			exit 1;
		fi	
		if [[ $IS_SILENT = false ]]; then
			echo "The Following Keys were found attached to the specified user:"
			for i in ${KEYIDS[@]}; do echo $i; done
			echo "What action do you want to perform?"
			select opt in "Continue" "Exit"; do
				case $opt in
					Continue ) break;;
					Exit ) exit;;
				esac
			done
		fi
	fi
else
    echo $(cat error.codecommit.keylist)
	exit 1;
fi

#Create the SSH keys
PWD=$(date +"%N" | sha256sum | base64 | head -c 12);
ssh-keygen -t rsa -f ${USERNAME_RSA[0]}_id_rsa -N $PWD
if [ $? -ne 0 ]
then
    echo "OMG you killed key generation!"
	exit 1;
else
    echo "Successfully created keys: ${USERNAME_RSA[0]}_id_rsa & ${USERNAME_RSA[0]}_id_rsa.pub"
fi

#upload the SSH Public key, returns the ID
KEYUPLOAD=(aws iam upload-ssh-public-key --user-name $IAM_USERNAME --ssh-public-key-body file://$HOME/${USERNAME_RSA[0]}_id_rsa.pub)
if "${KEYUPLOAD[@]}" > jsonoutput.codecommit.keyupload 2> error.codecommit.keyupload; then
   KEYID=$(cat jsonoutput.codecommit.keyupload | jq '.SSHPublicKey.SSHPublicKeyId')
   if [[ -z "$KEYID" ]]; then
		echo "OMG THERE IS NO KEYID !?!?!?!"
		exit 1;
	fi
	echo "Successfully uploaded key: ${USERNAME_RSA[0]}_id_rsa.pub"
else
    echo $(cat error.codecommit.keyupload)
	exit 1;
fi

echo "Key Password: $PWD"
echo "AWS KeyID: $KEYID"
echo "User Keys: /$HOME/${USERNAME_RSA[0]}_id_rsa & /$HOME/${USERNAME_RSA[0]}_id_rsa.pub"