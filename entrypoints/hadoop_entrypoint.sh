#!/bin/bash


start_journalnode() {
    hdfs --daemon start journalnode
    sleep 5
}

configure_zookeeper() {

    echo "${HOSTNAME: -1}" >  /home/hadoop/zookeeper/myid
    zkServer.sh start
}

format_namenode() {
    if [[ "$(hostname)" == "master1" ]]; then
        if [ ! -d "/tmp/hadoop-root/dfs/name/current" ]; then
            echo "Formatting NameNode on master1..."
            hdfs namenode -format
        else
            echo "NameNode already formatted, skipping..."
        fi
        if echo "ls /hadoop-ha" | zkCli.sh -server master1:2181 | grep -q ashrafcluster; then
            echo "ZKFC already formatted, skipping..."
        else
            echo "Formatting ZKFC..."
            hdfs zkfc -formatZK
        fi
    else
        echo "This is not master1, skipping NameNode formatting."
    fi
	echo "All JournalNodes are active. Starting NameNode on $(hostname)..."
	hdfs --daemon start namenode
}

wait_for_namenode() {
    if [[ "$(hostname)" != "master1" ]]; then
        while true; do
            if curl -s "http://master1:9870/jmx" | grep -q "NameNode"; then
                echo "NameNode is active on master1. Proceeding..."
                break
            else
                echo "Waiting for NameNode on master1..."
                sleep 5
            fi
        done
    else
        echo "This is master1, skipping NameNode check."
    fi
}

bootstrap_namenode() {
    if [[ "$(hostname)" != "master1" ]]; then
        if [ ! -d "/tmp/hadoop-hadoop/dfs/name/current" ]; then
            echo "Formatting NameNode on $(hostname)..."
            hdfs namenode -bootstrapStandby
        else
            echo "NameNode already formatted, skipping..."
        fi
    fi
	echo "All JournalNodes are active. Starting NameNode on $(hostname)..."
	hdfs --daemon start namenode
}

start_services() {
    echo "Starting ZKFC..."
    hdfs --daemon start zkfc
    echo "Starting ResourceManager..."
    yarn --daemon start resourcemanager
    echo "All services started."
}


start_worker_service(){
    hdfs --daemon start datanode
    yarn --daemon start nodemanager
}

tail_forever() {
    tail -f /dev/null
}



if [[ "$HOSTNAME" == *master* ]]; then
    start_journalnode
    configure_zookeeper
    format_namenode
    wait_for_namenode
    bootstrap_namenode
    start_services
else
    start_worker_service
fi

tail_forever
