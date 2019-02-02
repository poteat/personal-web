#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo 'A commit message is required'
    exit 1
fi

echo -e "\033[0;32mBuilding project...\033[0m"

hugo -t mainroad

echo -e "\033[0;32mDeploying updates to source repo...\033[0m"

git add .
git commit -m "$1"
git push origin master

echo -e "\033[0;32mDeploying updates to public repo...\033[0m"

cd public
git add .
msg="rebuilding site `date`"
git commit -m "$msg"
git push origin master

cd ..