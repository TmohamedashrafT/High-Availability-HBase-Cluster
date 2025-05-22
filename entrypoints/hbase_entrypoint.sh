#!/bin/bash

start_hadoop_worker_service(){
    echo "Starting Hadoop worker services: DataNode and NodeManager"
    hdfs --daemon start datanode
    yarn --daemon start nodemanager
}

start_hbase_hmaster(){
    echo "Starting HBase HMaster"
    $HBASE_HOME/bin/hbase master start
}

start_hbase_regionserver(){
    echo "Starting HBase RegionServer"
    $HBASE_HOME/bin/hbase  regionserver start
}

HOSTNAME=$(hostname)
echo "Container hostname: $HOSTNAME"

if [[ $HOSTNAME == hmaster* ]]; then
    start_hbase_hmaster

elif [[ $HOSTNAME == rs_worker* ]]; then
    start_hadoop_worker_service
    start_hbase_regionserver

else
    start_hadoop_worker_service
    echo "Hostname is neither hmaster nor rs_worker, only started Hadoop worker services"
fi

# Prevent container from exiting if necessary
tail -f /dev/null
