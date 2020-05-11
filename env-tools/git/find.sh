#!/bin/bash
#loop through all repos and find something using grep
SEARCHFOR=$1
BRANCHNAME=$2

function find {
	for i in $1/*; do
		echo "$i"
		git -C "$(cut -d'.' -f1 <<<"$i")" grep $SEARCHFOR $BRANCHNAME
	done
}

for f in *; do
    if [ -d "$f" ];then
	echo "$ "
	find $f
    fi
done
