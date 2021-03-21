#!/bin/bash
hugo -t mainroad -d poteat.github.io
cd poteat.github.io
git push origin HEAD:master
