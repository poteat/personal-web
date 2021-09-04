#!/bin/bash
hugo -t mainroad -d poteat.github.io
cd poteat.github.io
git pull origin HEAD:master
git add .
git commit . -m "Update website"
git push origin HEAD:master
cd ..
git add .
git commit . -m "Update website"
git push origin HEAD:master
