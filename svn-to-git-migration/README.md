# SVN to GIT Scripts

These scripts were made to support a Mass Migration from SVN to GIT. They pull a single SVN repository with multiple modules and individual stdlayout under each module. It then combines them into a single repository based on the project file you give it (under /ModuleName).

This process preserves the entire history of the project, so the history of files/folders/branches/tags are all combined and retained in the new GIT Repo prefixed by the module name it came from.

While these scripts work for our situations, use at your own risk as with all migrations TEST TEST TEST!

##Prerequisites
* cygwin or linux (tested on both)
* BASH
* SVN (1.8+)installed and on the system path
* SVN Server (1.6+)
* GIT (2.1.4+) installed and on the system path
* GIT SVN (2.1.4+) installed and on the system path. On some Linux distributions it is not installed with git.
* SVNRepository credentials saved locally (otherwise it will ask you to login if authentication is required).
* Enough HD space for the repositories (+3X their size)
* A home directory (current scritps are defaulted to the current user home dir)
* Patience and Knowledge

##Files:
* svnauthors.sh
 * This iterates over all the directories in the current folder and outputs all the SVN Authors to a file. It then sorts that file so only Uniques are left. You must edit the file to put in the correct email for people (or don't if you like them wrong).
* svnupgrade.sh
 * This iterates over all the directories in the current folder and runs the svn upgrade command. This was made because some SVN's I operated on were pretty old and it's important to move them up (locally) so the authors script can run properly.
* stgandcombine.sh
 * Heart and soul, this clones the repo from SVN, moves all files to a subfolder (same name as the module) and all successfully migrated repo's are then combined into 1 GIT repo.
 * All traces of the previous link to SVN are removed... THIS IS ONE WAY ONLY (why would you want to go back?).
 * depends on 2 files, the config.properties and your project list, also has 1 input of what you want the combined GIT repository to be named.
* config.properties
 * This holds currently only the svnrepo location in it (svnrepo=X)
* projects.txt
 * This holds the list of Modules (subdirs under the Repo location) to convert.
 * See projects.example
* authors.txt
 * This is the author list to be used by the git svn command. 
 * Generate from svnauthors.sh if you don't already have one.

##Layouts supported:
###Layout 1: 
 * SVN: servername/reponame/modulename/stdlayout
```
RepoA
   ProjectA
      trunk
      branches
      tags
   ProjectB
      trunk
      branches
      tags
```
 * GIT: /reponame/(module1/2/3)
```
RepoA
   Local
      master
      ProjectA/BranchA
      ProjectB/BranchA
   tags
      ProjectA/TagA
      ProjectB/TagA
   Working Directory
      ProjectA/<Code>
      ProjectB/<Code>
```

#Usage:
1. Generate an authors.txt (svn commiter list) on the projects, if you do not then git svn and the scripts will complain. If you already have one, just name it authors.txt and place it in the same directory with the scripts.
2. Setup a projects.txt (can name it whatever you want) with a list of projects (see projects.example)
3. Setup a config.properties with the correct svnrepo=X in it, this should be in the format specified in the config.properties already (1 line only, no spaces)
4. execute stgandcombine.sh
 * from command line "stgandcombine.sh [gitrepositoryname] [projects.txt]"
 * Example: "./stgandcombine.sh gitrepo1 projects.txt"
5. Push the GIT repo to your GIT server
6. 

#Recomendations:
* Before Migration: 
 * Always clean out your SVN repo of branches that were never commited to.
 * Delete irelevant SVN TAGS.
* Random Notes:
 * In SVN if you don't tell it to merge history with the merges then you should of! Otherwise history in branches will be lost when you delete a branch.

#Links:
* SVN Repo Layouts: http://svnbook.red-bean.com/nightly/en/svn.reposadmin.planning.html#svn.reposadmin.projects.chooselayout
* Cygwin: https://cygwin.com/install.html
* Cygwin w/SVN: https://ist.berkeley.edu/as-ag/tools/howto/cygwin.html
* Cygwin w/Git: http://www.celinio.net/techblog/?p=818

Orig Author: Lawrence Cutlip-Mason 7/1/2015
