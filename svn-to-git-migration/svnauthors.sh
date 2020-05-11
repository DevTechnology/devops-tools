#!/bin/bash
for d in */ ; do
    echo "$d"
	cd $d
	authors=$(svn log -q | grep -e '^r' | awk 'BEGIN { FS = "|" } ; { print $2 }' | sort | uniq)
	for author in ${authors}; do
		echo "${author} = ${author} <USER@DOMAIN>";
		echo "${author} = ${author} <USER@DOMAIN>" >> ../authors.txt;
	done
	cd ..
	sort authors.txt | uniq > authors_trimmed.txt
done
