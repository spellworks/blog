#!/bin/sh
echo "build at `pwd` `date`"
git reset --hard HEAD
git pull
hexo clean
hexo d -g
echo "built successfully"
