#!/bin/bash

#Check these variables accordingly to your plugin

PLUGINNAME="your-plugin-name.php" #CHANGE THIS LINE FOR YOUR PLUGIN
#============================
GITDIR="git"
SVNDIR="svn"

#!/bin/bash
cd "$PWD/$GITDIR"

git status
# warn if there are uncommitted changes!

git pull origin master

# Check version in readme.txt is the same as plugin file
NEWVERSION1=`grep "^Stable tag" readme.txt | awk -F' ' '{print $3}'`
echo "readme.txt version: $NEWVERSION1"
NEWVERSION2=`grep "Version" $PLUGINNAME | awk -F' ' '{print $3}'`
echo "$PLUGINNAME version: $NEWVERSION2"
if [ "$NEWVERSION1" != "$NEWVERSION2" ]; then echo "Versions don't 
match. Exiting...."; exit 1; fi
echo "Versions match in readme.txt and PHP file. Let's proceed..."

# sed to bump version?
# git commit -am "Bumped version up"

git tag -f -s $NEWVERSION1 -m "Tagged to match version in SVN"

echo "Pushing git master to origin, with tags"
git push origin master
git push origin master --tags

cd ../$SVNDIR/

svn update

# use rsync --delete to sync all add/delete changes?
cp -r ../$GITDIR/* ./trunk
svn add trunk --force
svn ci -m "Sync with git"

# Git tag -> SVN-tag
svn copy trunk tags/$NEWVERSION1
svn ci -m "Tagged version $NEWVERSION1"
