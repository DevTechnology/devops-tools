#!/bin/bash
#loop through all local git repos and replace the remote (repo name is folder name)
#cli param 1 is the org name in github

ORG=$1

function update {
	for i in $1; do
	    
		echo "$i"
		git -C "$(cut -d'.' -f1 <<<"$i")" remote remove origin
		git -C "$(cut -d'.' -f1 <<<"$i")" remote add origin git@github.com:$ORG/$(basename "${i%.*}").git
		#Enable next line to do a fetch
		#git -C "$(cut -d'.' -f1 <<<"$i")" fetch
	   
	done
}

for f in *; do
    if [ -d "$f" ];then
	    echo "$f"
	    update $f
    fi
done
