#!/bin/bash
hugo -t mainroad -d poteat.github.io
cd poteat.github.io
git pull origin HEAD:master
git commit . -m "Update website"
git push origin HEAD:master
