#!/bin/bash -e

# 处理环境变量
TARGET=$TARGET # 编译后存储位置
BUILD_ENV=$BUILD_ENV
TEMP_CACHE=$TEMP_CACHE
GITHUB_PROXY=$GITHUB_PROXY

if [ ! -n $TARGET ]; then
    TARGET=./target
fi

if [ ! -n $BUILD_ENV ]; then
    BUILD_ENV=shell
fi

if [ ! -n $TEMP_CACHE ]; then
    TEMP_CACHE=./source
fi




# 前置条件
function do_preset() {
    mkdir $TARGET $TEMP_CACHE
    if [ $? -nq 0 ]; then
        echo "init directory failed!"
    fi
}

# 从shell命令中构建
function build_front_from_shell() {

}

# 从docker中构建
function build_front_from_docker() {
    echo -e "current not sopport from docker build!\nexit"
    return 2
}

fucntion main() {
    
}



