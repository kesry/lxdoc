#!/bin/bash -e

# 清除编译的残留文件
rm -rf $2/*

for i in {workbench,whiteboard,sheet,ppt,doc,note}
do
    cd $1/$i
    echo "开始编译${i}项目"
    npx vite build
    if [ $i == "workbench"]; then
        cp -r $1/$i/dist/* $2/
    else
        cp -r dist $2/$i
    fi
done
echo "开始编译markdown项目"
cd $1/markdown
node --max-old-space-size=2048 ./node_modules/.bin/vite build
cp -r $1/markdown/dist $2/markdown