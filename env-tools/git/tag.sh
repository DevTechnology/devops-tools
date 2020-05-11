#!/bin/bash
#Tag every git repo in local workspace
TAGNAME=$1
BRANCHNAME=$2


function tag {
	for i in $1; do
		echo "$i"
		
    #OMG DELETE IT!
		#git -C "$(cut -d'.' -f1 <<<"$i")" tag -d $TAGNAME
		#git -C "$(cut -d'.' -f1 <<<"$i")" push --delete origin $TAGNAME
		
    	#SYNC STUFF
    	git -C "$(cut -d'.' -f1 <<<"$i")" checkout -f $BRANCHNAME
		git -C "$(cut -d'.' -f1 <<<"$i")" reset --hard $BRANCHNAME
		git -C "$(cut -d'.' -f1 <<<"$i")" pull
		sleep 1s #don't overload git
		#TAG STUFF
    	git -C "$(cut -d'.' -f1 <<<"$i")" tag $TAGNAME
		git -C "$(cut -d'.' -f1 <<<"$i")" push origin --tags

	done
}

for f in *; do
    if [ -d "$f" ];then
	    echo "$f"
	    tag $f
    fi
done
