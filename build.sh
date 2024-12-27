#!/bin/bash -e

# 处理环境变量
TARGET=$TARGET #编译类型
BUILD_ENV=$BUILD_ENV # 构建方式，docker or shell

BASE_DIR=$PWD
OLD_PATH=$PATH

if [ -z "${TARGET}" ]; then
    TARGET=all
else
    # 检查 TARGET 是否为 "front"、"back" 或 "all"
    case "${TARGET}" in
        front|back|all)
            # 如果 TARGET 是这三个值之一，则不需要做任何事情（或者可以在这里添加额外的逻辑）
            ;;
        *)
            # 如果 TARGET 不是这三个值之一，则打印错误消息
            echo "Not a valid build type [${TARGET}]. Only supports 'front', 'back', or 'all'."
            exit 1
            ;;
    esac
fi

if [ -z "${BUILD_ENV}" ]; then
    BUILD_ENV=shell
else
    case "${BUILD_ENV}" in 
        shell|docker)
            ;;
        *)
            echo "Not a valid BUILD_ENV [${BUILD_ENV}]. Only supports 'shell', 'docker'."
            exit 1
            ;;
    esac

fi

if [ -z "${TEMP_CACHE}" ]; then
    TEMP_CACHE=source
fi

if [ -z "${ENV_DIR}" ]; then
    ENV_DIR=env
fi

if [ -z "${TARGET_DIR}" ]; then
    TARGET_DIR=target
fi


mkdir -p $BASE_DIR/$TARGET_DIR $BASE_DIR/$TEMP_CACHE $BASE_DIR/$ENV_DIR


# 从shell命令中构建前端
function build_front_from_shell() {

    ARCH= && dpkgArch="$(dpkg --print-architecture)"
    case "${dpkgArch##*-}" in
        amd64) ARCH='x64' ;;
        ppc64el) ARCH='ppc64le' ;;
        arm64) ARCH='arm64' ;;
        armhf) ARCH='armv7l' ;;
        *) echo "unsupported architecture";  exit 1 ;;
    esac
    set -ex

    # 下载源码
    if [ ! -d "${BASE_DIR}/${TEMP_CACHE}/lx-doc" ]; then

        if [ ! -d "${BASE_DIR}/${TEMP_CACHE}/front" ]; then
            cd $BASE_DIR/$TEMP_CACHE
            git clone --depth=1 https://github.com/wanglin2/lx-doc.git
            mv lx-doc front
            # 修复上游路径错误
            mv $BASE_DIR/$TEMP_CACHE/front/workbench/src/pages/Error $BASE_DIR/$TEMP_CACHE/front/workbench/src/pages/error
        fi
        
    fi
    # 获取当前环境
    mkdir -p $BASE_DIR/$ENV_DIR/node
    if [ ! -d "${BASE_DIR}/${ENV_DIR}/node/16" ]; then
        cd $BASE_DIR/$ENV_DIR/node
        wget "https://nodejs.org/dist/v16.20.2/node-v16.20.2-linux-${ARCH}.tar.xz"
        tar -xJvf "node-v16.20.2-linux-${ARCH}.tar.xz"
        rm -rf "node-v16.20.2-linux-${ARCH}.tar.xz"
        mv "node-v16.20.2-linux-${ARCH}" 16
        rm -rf $BASE_DIR/$TARGET_DIR/*
    fi
    
    # 编译workbench
    if [ ! -d "${BASE_DIR}/${TEMP_CACHE}/front/workbench/dist" ]; then
        echo "-----------------正在编译workbench-----------------"
        PATH=$OLD_PATH:$BASE_DIR/$ENV_DIR/node/16/bin
        cd $BASE_DIR/$TEMP_CACHE/front/workbench
        npm i
        npm run build
    fi
    
    if [ ! -d "${BASE_DIR}/${TEMP_CACHE}/front/mind-map/dist" ]; then
        echo "-----------------正在编译mind-map-----------------"
        PATH=$OLD_PATH:$BASE_DIR/$ENV_DIR/node/16/bin
        cd $BASE_DIR/$TEMP_CACHE/front/mind-map
        npm i
        npm run build
        cp -rf dist $BASE_DIR/$TARGET_DIR/mind-map
    fi

    # 编译其他项目
    if [ ! -d "${BASE_DIR}/${ENV_DIR}/node/18" ]; then
        cd $BASE_DIR/$ENV_DIR/node
        wget "https://nodejs.org/dist/v18.20.5/node-v18.20.5-linux-${ARCH}.tar.xz"
        tar -xJvf "node-v18.20.5-linux-${ARCH}.tar.xz"
        rm -rf "node-v18.20.5-linux-${ARCH}.tar.xz"
        mv "node-v18.20.5-linux-${ARCH}" 18
    fi
    PATH=$OLD_PATH:$BASE_DIR/$ENV_DIR/node/18/bin

    for i in {whiteboard,sheet,ppt,doc,note}
    do
        if [ ! -d "${BASE_DIR}/${TEMP_CACHE}/front/${i}/dist" ]; then
            cd $BASE_DIR/$TEMP_CACHE/front/$i
            echo "-----------------正在编译${i}-----------------"
            npm i
            npx vite build
            cp -r dist $BASE_DIR/$TARGET_DIR/$i
        fi        
    done

    if [ ! -d "${BASE_DIR}/${TEMP_CACHE}/front/markdown/dist" ]; then
        echo "-----------------正在编译markdown-----------------"
        cd $BASE_DIR/$TEMP_CACHE/front/markdown
        npm i
        node --max-old-space-size=2048 ./node_modules/.bin/vite build
        cp -r dist $BASE_DIR/$TARGET_DIR/markdown
    fi

    # 编译flowchart
    echo "-----------------正在编译flowchart-----------------"
    if [ ! -d "${BASE_DIR}/${ENV_DIR}/java" ]; then
        
        ARCH=
        dpkgArch="$(dpkg --print-architecture)" 
        case "${dpkgArch##*-}" in 
            amd64) ARCH='x64' ;; 
            ppc64el) ARCH='ppc64le' ;;
            arm64) ARCH='aarch64' ;;
            armhf) ARCH='arm' ;;
            *) echo "unsupported architecture"; exit 1 ;;
        esac

        mkdir -p $BASE_DIR/$ENV_DIR/java
        cd $BASE_DIR/$ENV_DIR/java
        wget "https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u432-b06/OpenJDK8U-jdk_${ARCH}_linux_hotspot_8u432b06.tar.gz" 
        tar -xzvf "OpenJDK8U-jdk_${ARCH}_linux_hotspot_8u432b06.tar.gz" && mv jdk8u432-b06 8
        rm -rf "OpenJDK8U-jdk_${ARCH}_linux_hotspot_8u432b06.tar.gz"

    fi

    # 安装ant
    if [ ! -d "${BASE_DIR}/${ENV_DIR}/ant" ]; then
        cd $BASE_DIR/$ENV_DIR/
        wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.15-bin.tar.xz
        tar -xJvf apache-ant-1.10.15-bin.tar.xz && mv apache-ant-1.10.15 ant
        rm -rf apache-ant-1.10.15-bin.tar.xz
    fi
    PATH=$PATH:$BASE_DIR/$ENV_DIR/java/8/bin:$BASE_DIR/$ENV_DIR/ant/bin
    
    if [ ! -d "${BASE_DIR}/${TEMP_CACHE}/front/flowchart/src/main/webapp" ]; then
        wget https://github.com/jgraph/drawio/archive/refs/tags/v24.7.17.tar.gz && tar -xzvf v24.7.17.tar.gz
        cp -rf drawio-24.7.17/etc/integrate/ $BASE_DIR/$TEMP_CACHE/front/flowchart/etc/
        rm -rf v24.7.17.tar.gz drawio-24.7.17    
        cd $BASE_DIR/$TEMP_CACHE/front/flowchart    
        npm i
        npm run build
        cp -r $BASE_DIR/$TEMP_CACHE/front/flowchart/src/main/webapp $BASE_DIR/$TARGET_DIR/flowchart
    fi

    # 处理workbench
    cp -rf $BASE_DIR/$TEMP_CACHE/front/workbench/dist/* $BASE_DIR/$TARGET_DIR/
}

# 从docker中构建前端
function build_front_from_docker() {
    echo -e "current not sopport from docker build!\nexit"
    exit 0
}

# 从shell中构建后端
function build_back_from_shell() {
    if [ ! -d "${BASE_DIR}/${ENV_DIR}/java" ]; then
        
        ARCH=
        dpkgArch="$(dpkg --print-architecture)" 
        case "${dpkgArch##*-}" in 
            amd64) ARCH='x64' ;; 
            ppc64el) ARCH='ppc64le' ;;
            arm64) ARCH='aarch64' ;;
            armhf) ARCH='arm' ;;
            *) echo "unsupported architecture"; exit 1 ;;
        esac

        mkdir -p $BASE_DIR/$ENV_DIR/java
        cd $BASE_DIR/$ENV_DIR/java
        wget "https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u432-b06/OpenJDK8U-jdk_${ARCH}_linux_hotspot_8u432b06.tar.gz" 
        tar -xzvf "OpenJDK8U-jdk_${ARCH}_linux_hotspot_8u432b06.tar.gz" && mv jdk8u432-b06 8
        rm -rf "OpenJDK8U-jdk_${ARCH}_linux_hotspot_8u432b06.tar.gz"

    fi

    # maven环境
    if [ ! -d "${BASE_DIR}/${ENV_DIR}/maven" ]; then
        cd $BASE_DIR/$ENV_DIR/ 
        wget https://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz 
        tar -xzvf apache-maven-3.3.9-bin.tar.gz && mv apache-maven-3.3.9 maven
        rm -rf apache-maven-3.3.9-bin.tar.gz
    fi

    if [ ! -d "${BASE_DIR}/${TEMP_CACHE}/lx-doc" ]; then
        if [ ! -d "${BASE_DIR}/${TEMP_CACHE}/back" ]; then
            cd  $BASE_DIR/$TEMP_CACHE
            git clone -b personal https://github.com/yomea/lx-doc.git --depth=1 
            mv lx-doc back
            cp -rf $BASE_DIR/pom.xml $BASE_DIR/$TEMP_CACHE/back/pom.xml
            cp -rf $BASE_DIR/core.pom.xml $BASE_DIR/$TEMP_CACHE/back/lx-core/pom.xml
            sed -i "s/NOW()/datetime('now')/i" $BASE_DIR/$TEMP_CACHE/back/lx-core/src/main/resources/mybatis/*.xml
        fi
    fi
    
    if [ ! -d "${BASE_DIR}/${TEMP_CACHE}/back/lx-core/target" ]; then
        PATH=$OLD_PATH:$BASE_DIR/$ENV_DIR/java/8/bin:$BASE_DIR/$ENV_DIR/apache/bin
        cd $BASE_DIR/$TEMP_CACHE/back
        mvn -DskipTests -U clean package
        cp lx-core/target/lx-doc.jar $BASE_DIR/$TARGET_DIR/
    fi
    
    

}

# 从shell构建全部
function build_all_from_shell() {
    build_front_from_shell
    build_back_from_shell
}




if [ "${1}" == "clean" ]; then
    CLEAN_TARGET=$2
    if [ -z "${CLEAN_TARGET}" ]; then
        rm -rf $BASE_DIR/$TEMP_CACHE/*
        rm -rf $BASE_DIR/$ENV_DIR/*
        rm -rf $BASE_DIR/$TARGET_DIR/*
        exit 0
    fi
    if [ "${CLEAN_TARGET}" == "back" ]; then
        rm -rf $BASE_DIR/$TARGET_DIR/lx-doc.jar
        exit 0
    fi

    if [ "${CLEAN_TARGET}" == "env" ]; then
        rm -rf $BASE_DIR/$ENV_DIR/*
        exit 0
    fi

    if [ "${CLEAN_TARGET}" == "front" ]; then
        for i in {whiteboard,sheet,ppt,doc,note,assets,markdown,mind-map,index.html,logo.svg}
        do
            rm -rf $BASE_DIR/$TARGET_DIR/$i
        done
        
        exit 0
    fi

    if [ "${CLEAN_TARGET}" == "source" ]; then
        rm -rf $BASE_DIR/source/*
        exit 0
    fi

elif [ "${1}" == "help" ]; then

    echo "用法：TARGET=[option one] BUILD_ENV=[option two] bash build.sh [option three] [option four]"
    echo "option one: 可选值。"
    echo -e "\t1) all: 编译全部（默认值）"
    echo -e "\t2) font: 编译前端"
    echo -e "\t3) back: 编译后台"
    echo "option two: 可选值。"
    echo -e "\t1) shell: 从shell中编译源代码（默认值）"
    echo -e "\t2) docker: 用docker环境编译源代码"
    echo "option three: 可选值。clean|help "
    echo -e "\t1) clean: 从shell中清除源码，环境或者编译好的文件，option four为空时，默认清除所有编译的中间文件"
    echo -e  "\t\toption four"
    echo -e  "\t\t\t1. back 清除后端文件"
    echo -e  "\t\t\t2. env 清除环境文件"
    echo -e  "\t\t\t3. front 清除前端编译的文件"
    echo -e  "\t\t\t4. source 清除源代码文件"
    echo -e "\t2) help: 显示帮助信息"

else
    # rm -rf $BASE_DIR/$TEMP_CACHE/*
    # rm -rf $BASE_DIR/$TARGET_DIR/*
    if command -v apt-get &> /dev/null && [ -d /etc/apt ]; then
        apt update -y && apt install tar git xz-utils -y
    elif command -v yum &> /dev/null && [ -d /etc/yum.repos.d ]; then
        yum update -y && yum install tar git xz-utils -y
    else
        echo "Only supports 'apt-get' and 'yum' "
        exit 1
    fi
    build_${TARGET}_from_${BUILD_ENV}
    echo "success"
fi