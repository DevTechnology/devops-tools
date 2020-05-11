#!/bin/bash
for d in */ ; do
    echo "$d"
	cd $d
	svn upgrade
	cd ..
done
