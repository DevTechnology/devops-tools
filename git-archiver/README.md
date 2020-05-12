# git archiver

### This bash based tool helps to archive the ***master*** branch of a single repository as a new orphan branch of an archive repository without losing git commit log history.  

This script assumes that the branch that should be archived from the source repository is HEAD. It does not archive all branch history. If you need to retain all branch history then consider creating a git bundle using the --all option and saving the bundle in a share location. Consider that needing multiple branches archived may be an indicator that the project is not a candidate for archival as it may still be actively being developed ?

The archive repository is assumed to have minimal instructions in a README at the master branch and nothing else. All archivals are added into new orphan branch of the same name as the repository being archived.

This script does not modify any git remote repositories.  After performing the migration the user must review the changes in the archive repo and push the changes to a remote only if they are satisfied.

### Usage:

```sh
$ Usage: ./git-archiver.sh TARGET_ARCHIVE_REPO_URL SOURCE_GIT_CLONE_URL
```

### Requirements:
- bash version 4.2+
- git command line client available in bash shell

### Example:

```sh
$ ./git-archiver.sh git@github.com:MyOrganization/ARCHIVE-repo.git git@github.com:MyOrganization/obsolete-repo.git  
```

### How to checkout only an archived repo:

The ***--single-branch*** option for ***git clone*** combined with ***-b <project-name-as-branch-name>*** should be used to prevent downloading all archived repositories.

#### Example to checkout an archived repository:

```sh
$ git clone --single-branch -b my-retired-project git@github.com:MyOrganization/ARCHIVE-repo.git
```

#### Get a list of archived projects from the archive repository without cloning:

```sh
$ git ls-remote git@github.com:MyOrganization/ARCHIVE-repo.git
```

