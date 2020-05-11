# git mono repo migrator

### This bash based tool helps to migrate multiple individual related repos into a mono repo structure without losing git commit log history from each individual repository.  

A mono repository structure has both advantages and disadvantages.  [The Wikipedia page does a decent job of summarizing.](https://en.wikipedia.org/wiki/Monorepo)  Mono repos are particularly useful for organizing sets of repositories in the absence of features such as multiple GitHub **organizations** or GitLab **groups** and very useful in managing atomic commits where the implementation of features or code changes spans multiple components.

This script does not modify any git remote repositories.  After performing the migration the user must review the changes in the mono repo and push the changes to a remote only if they are satisfied with the migration.

### Usage:

```sh
$ ./mono-repo.sh TARGET_GIT_MONO_REPO_URL SOURCE_GIT_CLONE_URL_1 ... [SOURCE_GIT_CLONE_URL_N]
```

### Requirements:
- bash version 4.2+
- git command line client available in bash shell

### Example:

```sh
$ ./mono-repo.sh git@github.com:MyOrganization/my-koolapp-mono-repo.git git@github.com:MyOrganization/koolapp-microservice-one.git git@github.com:MyOrganization/koolapp-microservice-two.git git@github.com:MyOrganization/koolapp-ui-angular.git 
```
#### Resulting Folder Structure in my-koolapp-mono-repo:

```
my-koolapp-mono-repo/
├── koolapp-microservice-one/
│   ├── <koolapp-microservice-one src files...>
├── koolapp-microservice-two/
│   ├── <koolapp-microservice-two src files...>
├── koolapp-ui-angular/
│   ├── <koolapp-ui-angular src files...>
```

### How to checkout only some directories of a mono repo:

The ***--sparse*** option for ***git clone*** initializes git to expect to only work with certain specified directories.  The ***--no-checkout*** option prevents checking any files or branches out until the relevant directories / components are specified using the command:

 ***git sparse-checkout set directory1 directory2 ... directoryn***

#### Example to checkout and work on only the UI code:

```sh
$ git clone --sparse --no-checkout git@github.com:MyOrganization/my-koolapp-mono-repo.git
...
$ git sparse-checkout set koolapp-ui-angular

```

