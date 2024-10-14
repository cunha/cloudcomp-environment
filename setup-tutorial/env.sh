#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export HADOOP_HOME=/home/vagrant/hadoop-3.3.1
export HADOOP_CONFIG="$HADOOP_HOME/etc/hadoop"
export HBASE_HOME=/home/vagrant/hbase-2.3.7
export HBASE_CONF="$HBASE_HOME/conf"
export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HBASE_HOME/bin:$PATH
