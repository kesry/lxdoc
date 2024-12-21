FROM node:18.20-bullseye-slim as builder

MAINTAINER orgic@qq.com

RUN apt update && apt install wget curl git python-is-python3 tree -y && mkdir -p /source /target/webapp /env/java

WORKDIR /source

COPY front-build.sh .
COPY init.sql .
COPY init.py .
COPY entrypoint.sh .
COPY application.yaml .

RUN cp entrypoint.sh /target/ && cp application.yaml /target/ && \
cd /source && \git clone --depth=1 https://github.com/wanglin2/lx-doc.git && mv lx-doc front && \
bash /source/front-build.sh /source/front /target/webapp/


ENV JDK_VERSION jdk8u432-b06 

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
&& case "${dpkgArch##*-}" in \
  amd64) ARCH='x64' ;; \
  ppc64el) ARCH='ppc64le' ;; \
  arm64) ARCH='aarch64' ;; \
  armhf) ARCH='arm' ;; \
  i386) ARCH='x86-32' ;; \
  *) echo "unsupported architecture"; exit 1 ;; \
esac \
&& set -ex  \
&& cd /env/java && wget 'https://github.com/adoptium/temurin8-binaries/releases/download/${JDK_VERSION}/OpenJDK8U-jdk_${ARCH}_linux_hotspot_8u432b06.tar.gz' \
&& tar -xzvf "OpenJDK8U-jdk_${ARCH}_linux_hotspot_8u432b06.tar.gz" && mv $JDK_VERSION 8 \
&& cd /env && wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.15-bin.tar.xz \
&& wget https://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz \
&& tar -xJvf apache-ant-1.10.15-bin.tar.xz && mv apache-ant-1.10.15 ant \
&& tar -xjvf apache-maven-3.3.9-bin.tar.gz && mv apache-maven-3.3.9 maven \
&& export ANT_HOME=/env/ant \
&& export JAVA_HOME=/env/java/8 && export JRE_HOME=/env/java/8/jre \
&& export MAVEN_HOME=/env/maven \
&& export PATH=$PATH:$JAVA_HOME/bin:$ANT_HOME/bin:$MAVEN_HOME/bin \
&& java --version && mvn -v \
&& cd /source/front/flowchart && npm i && npm run build \
&& cp -r /source/front/flowchart/dist /target/webapp/flowchart \
&& cd /source && git clone -b personal https://github.com/yomea/lx-doc.git --depth=1 \
&& cd /source/lx-doc && mvn -DskipTests -U clean package \
&& cp /source/lx-doc/lx-core/target/lx-doc.jar /target/ \
&& DB_PATH=/target/lx_doc.db DB_INIT_SQL_PATH=/source/init.sql python3 /source/init.py \
&& tree /target

# 编译结束，开始创建发布镜像
FROM openjdk:8-jdk-alpine

MAINTAINER orgic@qq.com

RUN apk update && apk --no-cache add nginx tzdata \
&& cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& echo "Asia/Shanghai" > /etc/timezone \
&& apk del tzdata \
&& mkdir -p /app

WORKDIR /app

COPY --from=builder /target .

CMD ["sh", "/app/entrypoint.sh"]
