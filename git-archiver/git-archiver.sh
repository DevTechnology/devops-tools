#!/bin/bash
#
# Archive the HEAD of single repository into a single branch in an ARCHIVE repository by creating a new
# branch in the name of the original repository. This allows consolidation of
# older, defunct or ununsed repositories from cluttering up an organization account
# such as GitHub
#
# NOTE: This does not support Windows path separators and has not
#       been extensively tested with non standard repo URLs

readonly TEMPDIRNAME="temp-git-archiver_$(date +%F-%T | tr -d ":")"
readonly TEMPDIR="$(pwd)/$TEMPDIRNAME"
declare -g get_repo_name_result


output_usage() {
    echo -e "\nUsage: ./git-archiver.sh TARGET_ARCHIVE_REPO_URL SOURCE_GIT_CLONE_URL"
    echo -e "\nRequires the git cli be available in the PATH as well as permissions to the repositories"
}

# Extract the implied repository name by parsing the clone URL
# Result is placed in a global variable: get_repo_name_result
get_repo_name() {
    # If the clone URL ends in .git then it's a standard repository url
    if [[ $1 =~ .*\.git$ ]]
    then
        get_repo_name_result=$(echo "$1" | sed -e 's|.*/\(.*\)\.git|\1|')
    else
        # This is only to support filesystem based repository URLs and may not work
        # with some special character edge cases
        get_repo_name_result=$(echo "$1" | sed 's|/$||' | sed -e 's|.*/||')
    fi
}

# Move an individual repository into archive repository as a branch
archive_repo_into_branch() {
    local repo
    local repo_name

    repo="$1"
    repo_name="$2"

    cd "$TEMPDIR"
    git clone "$repo" 
    src_repo_commit_count=$(git -C "$TEMPDIR/$repo_name" log --oneline | wc -l)

    echo "Archiving HEAD of $repo_name at $repo into branch='$repo_name' of $archive_repo"

    ## Migrate src repo into mono repo
    local git_remote_name="$repo_name-to-archive"
    cd "$TEMPDIR/$archive_repo_name"
    git checkout --orphan "$repo_name"
    git rm -rf .
    git remote add "$git_remote_name" "$TEMPDIR/$repo_name"
    git fetch "$git_remote_name"
    git merge -m "Archiving HEAD of $repo_name at $repo into branch='$repo_name' of $archive_repo" "$git_remote_name"/master

    archive_repo_commit_count=$(git -C "$TEMPDIR/$archive_repo_name" log --oneline | wc -l)
}

main () {
    local get_repo_name_result
    local archive_repo
    local src_repo
    local src_repo_name
    local src_repo_commit_count
    local archive_repo_commit_count

    if [[ "$#" -ge 2 ]]
    then
        archive_repo="$1"
        src_repo="$2"
    else
        output_usage
        exit 1
    fi 

    # Extract the expected archive repo directory name
    local archive_repo_name
    get_repo_name "$archive_repo"
    archive_repo_name="$get_repo_name_result"

    ## Create the temporary work directory
    echo "Creating temp directory to perform work: $TEMPDIR"
    mkdir "$TEMPDIR"

    ## Clone the archive repo from git server and pull only the HEAD branch
    cd "$TEMPDIR"
    git clone --single-branch "$archive_repo"

    get_repo_name "$src_repo"
    src_repo_name="$get_repo_name_result"
    archive_repo_into_branch "$src_repo" "$src_repo_name"

    if [[ $archive_repo_commit_count -ge $src_repo_commit_count ]]
    then
        echo -e "\nSUCCESS !!\n\n Created new branch '$src_repo_name' in repository in $archive_repo_name at $archive_repo."
        echo "Please review and push changes to $archive_repo_name if you are satisfied using the following command: git push origin $src_repo_name"
        echo -e "\nRemember to delete the temp migration directory after you are done using the following command: rm -rf $TEMPDIR"
    else
        echo "WARNING: Unable to verify migration using git log commit counts. Please review results of archival attempt at $TEMPDIR"
    fi

    echo -e "\nWaiting for review of archived repo at [$TEMPDIR/$archive_repo_name], no changes have been pushed."
    echo "Only delete temp work directory if something went wrong or this was a test."
    echo -e "\nHow do you wish to proceed?"
    local delete_choice="Delete temp work directory"
    local auto_push_choice="WARNING: Accept and push changes without review then delete temp directory"
    local review_choice="Leave temporary directory for review"
    select choice in "$delete_choice" "$auto_push_choice" "$review_choice" ; do
        case $choice in
            "$delete_choice" ) cd "$TEMPDIR"/.. && rm -rf "$TEMPDIR"; break;;
            "$auto_push_choice" ) cd "$TEMPDIR/$archive_repo_name" && git push origin "$src_repo_name" && cd "$TEMPDIR"/.. && rm -rf "$TEMPDIR"; break;;
            "$review_choice" ) exit;;
        esac
    done
}

## Uncomment the below line to debug
#set -x
set -e
main "$@"
