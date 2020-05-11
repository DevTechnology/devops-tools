#!/bin/bash

#Config files.
if [ $# -lt 2 ]; then
  echo 1>&2 "$0: not enough arguments (need both arguments: CombinedGITRepoName ProjectFile)"
  exit 2
elif [ $# -gt 2 ]; then
  echo 1>&2 "$0: too many arguments (need both arguments: CombinedGITRepoName ProjectFile)"
  exit 2
fi
gitRepoName=$1
projectFile=$2
configFile="config.properties"


projectListArray=()
badProjectListArray=()

# Read a property from a property file
# @param propertyName (1)
# @param fileName (2)
getPropertyFromFile() {
# substitute "." with "\." so that we can use it as sed expression
fileName=$2;
cat $fileName | sed -n -e "s/^[ ]*//g;/^#/d;s/^$1=//p" | tail -1
}

# Read the file in parameter and fill the array named "array"
# @param fileName (1)
getProjectListArray() {
    i=0
    while read line; do
		[[ "$line" =~ ^#.*$ ]] && continue
		[ -z "$line" ] && continue
        projectListArray[i]=$line # Put it into the array
        i=$(($i + 1))
    done < $1
}

# Put project into the Project Error Array
# @param projectName (1)
projectError() {
    badProjectListArray+=($1)
}

# Convert repositories
# @param projectName (1)
executeRepositoryConversion() {
	echo "Clone the Repo:"
	git svn clone $svnrepo$1 --no-metadata -A authors.txt --stdlayout ~/$1
	if [ $? -ne 0 ]; then
		echo "git svn clone failed?"
		return 1
	fi
	
	echo "Clean the Git Cloned Repo:"
	cd ~/$1
	if [ $? -ne 0 ]; then
		echo "git svn clone failed to create the git dir?"
		return 1
	fi
	#Move Tags from Remote to Local, there might not be tags so don't bother checking for error
	cp -Rf .git/refs/remotes/origin/tags/* .git/refs/tags/
	#Remove Remote TAGS when done.
	rm -Rf .git/refs/remotes/origin/tags
	#Remove the trunk it's imported as master and not necessary so we remove it before moving branches to local
	rm -Rf .git/refs/remotes/origin/trunk
	#Move branches/codelines from Remote to Local.
	cp -Rf .git/refs/remotes/* .git/refs/heads/
	if [ $? -ne 0 ]; then
		echo "no branches/tags or trunk were found?"
		return 1
	fi
	#Remove all the remotes when complete.
	rm -Rf .git/refs/remotes
	
	echo "Rewrite the history to be at subdir: $1 in the Repo: $1"
	#Move all files to a subdirectory and rewrite every branch/tag/master
	git filter-branch --index-filter \
    'git ls-files -s | sed "s-\t\"*-&'$1'/-" |
    GIT_INDEX_FILE=$GIT_INDEX_FILE.new \
    git update-index --index-info &&
    mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE" || true
    ' --tag-name-filter cat -f -- --all
	if [ $? -ne 0 ]; then
		echo "git filter-branch failed?"
		return 1
	fi
	
	return 0
}

# Merge repositories
# @param projectName (1)
# @param combinedRepoName (2)
executeRepositoryMerge() {
	cd ~/$2
	if [ $? -ne 0 ]; then
		echo "Couldn't change to the ~/$2 combinedrepo directory?"
		return 1
	fi
	git remote add -f $1 ~/$1
	if [ $? -ne 0 ]; then
		echo "failed to add the ~/$1 repo as a remote. "
		return 1
	fi
	git merge -m'Merge commit (Project Migration from SVN to GIT)' $1/master
	if [ $? -ne 0 ]; then
		echo "git filter-branch failed?"
		return 1
	fi
	return 0
}

arrayContains () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 1; done
  return 0
}

cd ~
if [ $? -ne 0 ]; then
	echo "Failed to Change to Home Dir"
	break
fi

#Read the list of projects to be combined from the specified file
if [ -f "$projectFile" ]
then
getProjectListArray $projectFile
fi

#read the config file for operational properties
if [ -f "$configFile" ]
then
svnrepo=$(getPropertyFromFile svnrepo $configFile)
fi

for e in "${projectListArray[@]}"
do
    echo "Executing On Project: $e"
	cd ~
	if [ $? -ne 0 ]; then
		echo "Failed to Change to Home Dir"
		exit 1
	fi
	executeRepositoryConversion $e 2>&1 | tee -a ~/RC_$e.log
	if [[ $eRCResult -ne 0 ]]
	then
	  projectError $e
	  echo "ProjectName:$e Had an error"
	  continue
	fi

done

cd ~
if [ $? -ne 0 ]; then
	echo "Failed to Change to Home Dir"
	exit 1
fi
mkdir ~/$gitRepoName
if [ $? -ne 0 ]; then
	echo "Failed to Make Combined Repo Directory: $gitRepoName"
	exit 1
fi
cd ~/$gitRepoName
if [ $? -ne 0 ]; then
	echo "Failed to Change to Combined Repo Directory: $gitRepoName"
	exit 1
fi
git init .
if [ $? -ne 0 ]; then
	echo "Failed to initialize the Combined Repository: $gitRepoName"
	exit 1
fi
git commit --allow-empty -m'Initial commit (Project Migration from SVN to GIT)'
if [ $? -ne 0 ]; then
	echo "Failed to make an initial commit to the Combined Repository: $gitRepoName"
	exit 1
fi

for e in "${projectListArray[@]}"
do
    echo "$e"
	echo "${badProjectListArray[@]}"
	arrayContains "$e" "${badProjectListArray[@]}"
	if [ $? -ne 0 ]; then
		echo "Project $e was in the failure list, ignoring it and continuing with the next one."
		continue
	fi
	executeRepositoryMerge $e $gitRepoName 2>&1 | tee -a ~/RC_$e.log
done

cd ~/$gitRepoName
if [ $? -ne 0 ]; then
	echo "Couldn't change to the ~/$gitRepoName project directory?"
	exit 1
fi
cp -Rf .git/refs/remotes/origin/tags/* .git/refs/tags/
rm -Rf .git/refs/remotes/origin/tags
cp -Rf .git/refs/remotes/* .git/refs/heads/
if [ $? -ne 0 ]; then
	echo "no branches/tags or trunk were found in $gitRepoName ? Assuming original didn't have any"
fi
rm -Rf .git/refs/remotes

cd ~/$gitRepoName
for e in "${projectListArray[@]}"
do
    echo "$e"
	echo "${badProjectListArray[@]}"
	if [ $? -ne 0 ]; then
		echo "Project $e was in the failure list, ignoring it and continuing with the next one."
		continue
	fi
	git remote remove $e
	if [ $? -ne 0 ]; then
		echo "failed to remove the remote of $e from the $gitRepoName"
	fi
done
