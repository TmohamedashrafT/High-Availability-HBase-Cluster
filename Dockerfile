# === Stage 1: Base Hadoop & ZooKeeper Image ===
FROM ubuntu:24.04 AS hadoop

ARG HADOOP_VERSION=3.3.6
ARG ZK_VERSION=3.8.4
ARG JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        sudo \
        openjdk-8-jdk \
        tar \
        netcat-openbsd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create hadoop user with passwordless sudo
RUN useradd -ms /bin/bash hadoop && \
    echo "hadoop:hadoop" | chpasswd && \
    usermod -aG sudo hadoop && \
    echo "hadoop ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set environment variables
ENV JAVA_HOME=$JAVA_HOME
ENV HADOOP_HOME=/home/hadoop/packages/hadoop
ENV ZOOKEEPER_HOME=/home/hadoop/packages/zookeeper
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV HADOOP_LOG_DIR=/home/hadoop/hadoop/logs
ENV ZOO_LOG_DIR=/home/hadoop/zookeeper/logs
ENV HADOOP_USER_NAME=root
ENV PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin

# Create working directory and required folders
WORKDIR /home/hadoop
RUN mkdir -p \
    hadoop/logs \
    zookeeper/{logs,data} \
    packages

# Download and extract Hadoop and ZooKeeper
RUN wget https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    wget https://downloads.apache.org/zookeeper/zookeeper-${ZK_VERSION}/apache-zookeeper-${ZK_VERSION}-bin.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C packages && \
    tar -xzf apache-zookeeper-${ZK_VERSION}-bin.tar.gz -C packages && \
    mv packages/hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    mv packages/apache-zookeeper-${ZK_VERSION}-bin $ZOOKEEPER_HOME && \
    rm *.tar.gz

# Copy configuration and entrypoint
COPY hadoop/configs/hadoop_config/ $HADOOP_HOME/etc/hadoop/
COPY hadoop/configs/zoo.cfg $ZOOKEEPER_HOME/conf/
COPY entrypoints/hadoop_entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

# === Stage 2: Add HBase ===
FROM hadoop AS hadoop_hbase

ARG HBASE_VERSION=2.4.9
ENV HBASE_HOME=/home/hadoop/packages/hbase
ENV PATH=$PATH:$HBASE_HOME/bin

# Download and extract HBase
WORKDIR /home/hadoop
ADD https://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz packages/
RUN tar -xzf packages/hbase-${HBASE_VERSION}-bin.tar.gz -C packages && \
    mv packages/hbase-${HBASE_VERSION} $HBASE_HOME && \
    rm packages/hbase-${HBASE_VERSION}-bin.tar.gz

# Copy HBase config and new entrypoint
COPY hbase-site.xml $HBASE_HOME/conf/
COPY entrypoints/hbase_entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

EXPOSE 16000 16010 16020

ENTRYPOINT ["./entrypoint.sh"]
