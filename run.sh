#!/usr/bin/env bash

NAMENODE_FORMATTED_FLAG="/var/lib/hadoop/namenode-is-formatted"

if [[ ${HADOOP_ROLE,,} = namenode ]]; then

    echo "Will run in namenode mode"

    # Format namenode
    if [ -z "$STANDBY" ]; then

        echo "Formatting zookeeper"
        gosu hadoop $HADOOP_HOME/bin/hdfs zkfc -formatZK -nonInteractive

        if [ ! -f $NAMENODE_FORMATTED_FLAG ]; then
            echo "Formatting namenode..."
            gosu hadoop $HADOOP_HOME/bin/hdfs namenode -format -nonInteractive -clusterId $CLUSTER_NAME
            gosu hadoop touch $NAMENODE_FORMATTED_FLAG
        else
            echo "Will not format namenode: $NAMENODE_FORMATTED_FLAG exists"
        fi
    fi

    # Set this namenode as standby if required
    if [ -n "$STANDBY" ]; then
        echo "Starting namenode in standby mode..."
        gosu hadoop $HADOOP_HOME/bin/hdfs namenode -bootstrapStandby
    else
        echo "Starting namenode..."
    fi

    trap 'kill %1; kill %2' SIGINT SIGTERM

    gosu hadoop $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR namenode &

    # Start the zkfc
    gosu hadoop $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR zkfc &

    # Wait for cluster to be ready
    gosu hadoop $HADOOP_HOME/bin/hdfs dfsadmin -safemode wait

    # Create the /tmp directory if it doesn't exist
    gosu hadoop $HADOOP_HOME/bin/hadoop fs -test -d /tmp

    if [ $? != 0 ] && [ -z "$STANDBY" ]; then
        gosu hadoop $HADOOP_HOME/bin/hadoop fs -mkdir /tmp
        gosu hadoop $HADOOP_HOME/bin/hadoop fs -chmod -R 1777 /tmp
    fi

    while true; do sleep infinity; done

elif [[ ${HADOOP_ROLE,,} = datanode ]]; then

    echo "Will run in datanode mode"
    # Start the datanode
    echo "Starting datanode..."
    exec gosu hadoop $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR datanode

elif [[ ${HADOOP_ROLE,,} = journalnode ]]; then

    echo "Will run in journalnode mode"

    # Start the journalnode
    echo "Starting journalnode..."
    exec gosu hadoop $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR journalnode

elif [[ ${HADOOP_ROLE,,} = httpfsnode ]]; then
    echo "Will run in httpfsnode mode"
    gosu hadoop $HADOOP_HOME/bin/hdfs --config $HADOOP_CONF_DIR httpfs
else
    exec /bin/bash
fi
