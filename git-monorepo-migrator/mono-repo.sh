#!/bin/bash
#
# Consolidate multiple existing repos to a mono repo while preserving commit history
# All work is performed with master branch
#
# NOTE: This does not support Windows path separators and has not
#       been extensively tested with non standard repo URLs
#
# This technique for migrating a repository while preserving history
# was inspired by:
# https://medium.com/@filipenevola/how-to-migrate-to-mono-repository-without-losing-any-git-history-7a4d80aa7de2

readonly TEMPDIRNAME="temp-mono-repo_$(date +%F-%T | tr -d ":")"
readonly TEMPDIR="$(pwd)/$TEMPDIRNAME"
declare -g get_repo_name_result


output_usage() {
    echo -e "\nUsage: ./mono-repo.sh TARGET_GIT_MONO_REPO_URL SOURCE_GIT_CLONE_URL_1 ... [SOURCE_GIT_CLONE_URL_N]"
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

# Move an individual repository into a mono repository
# Step 1: Create a new commit that moves everything at the root of the repository into a folder
#         with the same name as the repository
# Step 2: Create a git remote reference to the individual repo from the mono repo
#         and perform a merge
# Step 3: Save to number of commits migrated for later validation
move_repo() {
    local repo
    local repo_name

    repo="$1"
    repo_name="$2"


    echo "Processing Repo $repo_name at $repo"

    cd "$TEMPDIR" && git clone "$repo"
    
    ## Move code into directory to preserve log
    cd "$TEMPDIR/$repo_name"
    mkdir "$repo_name"
    ls -A1 | grep -v "^$repo_name\|^.git$" | xargs -I{} git mv "{}" "$repo_name"
    git commit -m "Moving $repo_name into separate folder for migration to mono repo $mono_repo_name"

    ## Migrate src repo into mono repo
    local git_remote_name="$repo_name-to-monorepo"
    cd "$TEMPDIR/$mono_repo_name"
    git remote add "$git_remote_name" "$TEMPDIR/$repo_name"
    git fetch "$git_remote_name"
    git merge --allow-unrelated-histories -m "Migrating $repo_name git repository into $mono_repo_name git repository" "$git_remote_name"/master

    src_repo_commit_counts["$repo_name"]=$(cd "$TEMPDIR/$repo_name" && git log --oneline | wc -l)

}

main () {
    local get_repo_name_result
    local mono_repo
    local src_repos
    declare -A src_repo_names
    declare -A src_repo_commit_counts

    if [[ "$#" -ge 2 ]]
    then
        mono_repo="$1"
        shift
        src_repos=("$@")
    else
        output_usage
        exit 1
    fi 

    # Extract the expected mono repo directory name
    local mono_repo_name
    get_repo_name "$mono_repo"
    mono_repo_name="$get_repo_name_result"

    ## Create the temporary work directory
    echo "Creating temp directory to perform work: $TEMPDIR"
    mkdir "$TEMPDIR"

    ## Clone the src mono repo from git server
    cd "$TEMPDIR"
    git clone "$mono_repo"

    ## Save starting number of commits in mono repo
    local starting_mono_repo_commit_count
    starting_mono_repo_commit_count=$(git -C "$TEMPDIR/$mono_repo_name" log --oneline | wc -l)

    for curr_repo in "${src_repos[@]}"
    do 
        get_repo_name "$curr_repo"
        src_repo_names["$curr_repo"]="$get_repo_name_result"
        move_repo "$curr_repo" "$get_repo_name_result"
    done

    ## Verify everything worked
    local total_src_repos_commit_count
    local new_mono_repo_commit_count

    echo -e "\n\nNumber of starting git log entries for $mono_repo_name : $starting_mono_repo_commit_count"

    total_src_repos_commit_count=0
    for curr_repo_name in "${src_repo_names[@]}"
    do
        src_repo_commit_counts["$curr_repo_name"]=$(git -C "$TEMPDIR/$curr_repo_name" log --oneline | wc -l)
        echo "Number of git log entries for $curr_repo_name : ${src_repo_commit_counts["$curr_repo_name"]}"
        total_src_repos_commit_count=$(($total_src_repos_commit_count + ${src_repo_commit_counts["$curr_repo_name"]}))
    done

    new_mono_repo_commit_count=$(git -C "$TEMPDIR/$mono_repo_name" log --oneline | wc -l)
    echo "New number of git log entries for $mono_repo_name : $new_mono_repo_commit_count"
    echo "Expected minimum number of git log entries for $mono_repo_name : $(($total_src_repos_commit_count + $starting_mono_repo_commit_count))"

    if [[ $new_mono_repo_commit_count -ge $(($total_src_repos_commit_count + $starting_mono_repo_commit_count)) ]]
    then
        echo -e "\nSUCCESS !!\n\nMigrated separate repositories into $mono_repo_name."
        echo "Please review and push changes to $mono_repo_name if you are satisfied."
        echo -e "\nRemember to delete the temp migration directory after you are done using the following command: rm -rf $TEMPDIR"
    else
        echo "WARNING: Unable to verify migration using git log commit counts. Please review results of migration attempt at $TEMPDIR"
    fi

    echo -e "\nWaiting for review of merged repo at [$TEMPDIR/$mono_repo_name], no changes have been pushed."
    echo "Only delete temp work directory if something went wrong or this was a test."
    echo -e "\nHow do you wish to proceed?"
    local delete_choice="Delete temp work directory"
    local auto_push_choice="Accept and push changes without review then delete temp directory WARNING"
    local review_choice="Leave temporary directory for review"
    select choice in "$delete_choice" "$auto_push_choice" "$review_choice" ; do
        case $choice in
            "$delete_choice" ) cd "$TEMPDIR"/.. && rm -rf "$TEMPDIR"; break;;
            "$auto_push_choice" ) cd "$TEMPDIR/$mono_repo_name" && git push origin master && cd "$TEMPDIR"/.. && rm -rf "$TEMPDIR"; break;;
            "$review_choice" ) exit;;
        esac
    done
}

## Uncomment the below line to debug
#set -x
set -e
main "$@"
