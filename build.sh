#!/bin/sh
echo "build at `pwd` `date`"
git reset --hard HEAD
git pull
hexo clean
hexo generate
echo "built successfully"
