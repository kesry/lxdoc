#!/bin/bash -e

# 清除编译的残留文件
rm -rf $2/*

# 修复原项目的目录设置错误


for i in {whiteboard,sheet,ppt,doc,note,mind-map}
do
    cd $1/$i
    echo "开始编译${i}项目"
    npm i
    npx vite build
    cp -r $1/$i/dist $2/$i
done
echo "开始编译markdown项目"
cd $1/markdown
npm i
node --max-old-space-size=2048 ./node_modules/.bin/vite build
cp -r $1/markdown/dist $2/markdown
