#!/bin/bash
# This scripts expects to be run in a directory where
# wp-plugin-x.git and wp-plugin-x.svn
# exists and can be pushed and pulled.
# This script also assumes certain layout and contents
# of WP plugins according strictly to the official WP standards.

set -e # Stop on errors

if [[ -z "$@" ]]; then
    echo >&2 "You must supply an argument!"
    echo "Example: ./push-git-to-svn wp-https-domain-alias.git"
    exit 1
elif [[ ! -d "$@/.git" ]] && [[ ! -d "$@.git/.git" ]]; then
    echo >&2 "$@ is not a valid git repository!"
    exit 1
fi

PLUGINNAME=`echo $@ | cut -d '.' -f 1`
echo "Syncing plugin $PLUGINNAME to wordpress.org"

cd $PLUGINNAME.git

git status
# warn if there are uncommitted changes!

git pull

# Check version in readme.txt is the same as plugin file
NEWVERSION1=`grep "^Stable tag" readme.txt | awk -F' ' '{print $3}'`
echo "readme.txt version: $NEWVERSION1"

if [[ -f $PLUGINNAME.php ]]; then
  NEWVERSION2=`grep "Version" $PLUGINNAME.php | awk -F' ' '{print $3}'`
  echo "$PLUGINNAME.php version: $NEWVERSION2"
elif [[ -f `echo $PLUGINNAME | cut -d - -f 2-`.php ]]; then
  FILENAME=`echo $PLUGINNAME | cut -d - -f 2-`.php
  NEWVERSION2=`grep "Version" $FILENAME | awk -F' ' '{print $3}'`
  echo "$FILENAME version: $NEWVERSION2"
else
  echo "Plugin main php file not found. Exiting...."
  exit 1
fi

if [ "$NEWVERSION1" != "$NEWVERSION2" ]; then
  echo "Versions don't match. Exiting...."
  exit 1
fi

echo "Versions match in readme.txt and PHP file. Let's proceed..."

if [[ -d "../$PLUGINNAME.svn/tags/$NEWVERSION1" ]]; then
  echo "This tag already exists in SVN. Bump version number before upload. Exiting.."
  exit 1
fi

git tag -f -s $NEWVERSION1 -m "Tagged to match version in SVN"

echo "Pushing git master to origin, with tags"
git push origin master
git push origin master --tags


cd ../$PLUGINNAME.svn/trunk
svn update

# use rsync --delete to sync all add/delete changes?
cp ../../$PLUGINNAME.git/* .
svn add -q *
# Note: if a file is removed from git, it will not
# be automatically removed from svn.
svn ci -m "Sync with git"

# Git tag -> SVN-tag
cd ..
svn cp trunk tags/$NEWVERSION1
svn ci -m "Tagged version $NEWVERSION1"
