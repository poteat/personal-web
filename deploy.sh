#!/bin/bash

rm -rf ../poteat.github.io/
hugo -d ../poteat.github.io

cd ../poteat.github.io
git commit -am "website upload (`date`)"
git push
cd ../personal-web