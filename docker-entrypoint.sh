#!/usr/bin/env bash

export HADOOP_ROLE=${HADOOP_ROLE:="console"}
echo "Will run in $HADOOP_ROLE role"

CORE_SITE="$HADOOP_HOME/etc/hadoop/core-site.xml"
HDFS_SITE="$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
LOG_DIR="/var/log/hadoop/hdfs"
PID_DIR="/var/run/hadoop/hdfs"

CLUSTER_NAME=${CLUSTER_NAME:="mycluster"}
DFS_NAMESERVICE_ID=${DFS_NAMESERVICE_ID:="ns"}
HA_ZOOKEEPER_QUORUM=${HA_ZOOKEEPER_QUORUM:="zk:2181"}
DFS_NAMESERVICES=${DFS_NAMESERVICE_ID}

NS_DFS_NAMENODES=${NS_DFS_NAMENODES:="nn"}
NS_DFS_NAMENODE_RPC_ADDRESS_NN=${NS_DFS_NAMENODE_RPC_ADDRESS_NN:="nn:8020"}
NS_DFS_NAMENODE_HTTP_ADDRESS_NN=${NS_DFS_NAMENODE_HTTP_ADDRESS_NN:="nn:50070"}

addConfig () {

    if [ $# -ne 3 ]; then
        echo "There should be 3 arguments to addConfig: <file-to-modify.xml>, <property>, <value>"
        echo "Given: $@"
        exit 1
    fi

    xmlstarlet ed -L -s "/configuration" -t elem -n propertyTMP -v "" \
     -s "/configuration/propertyTMP" -t elem -n name -v $2 \
     -s "/configuration/propertyTMP" -t elem -n value -v $3 \
     -r "/configuration/propertyTMP" -v "property" \
     $1
}

if [ $HADOOP_CONF_DIR == ${HADOOP_HOME}/etc/hadoop ]; then

    # Incase using a external config directory
    chown -R hadoop:hadoop "$HADOOP_CONF_DIR"

    # Populate missing configuration files if using default $HADOOP_CONF_DIR
    cp -r -n ${HADOOP_HOME}/etc/hadoop_default/* ${HADOOP_CONF_DIR}/

    # Update core-site.xml
    : ${CLUSTER_NAME:?"CLUSTER_NAME is required."}
    : ${DFS_NAMESERVICE_ID:?"DFS_NAMESERVICE_ID is required."}
    addConfig $CORE_SITE "fs.defaultFS" "hdfs://${DFS_NAMESERVICE_ID}"
    addConfig $CORE_SITE "fs.trash.interval" ${FS_TRASH_INTERVAL:=1440}
    addConfig $CORE_SITE "fs.trash.checkpoint.interval" ${FS_TRASH_CHECKPOINT_INTERVAL:=0}
    addConfig $CORE_SITE "ipc.client.connect.retry.interval" 6000
    addConfig $CORE_SITE "ipc.client.connect.max.retries" 400

    # HTTPFS impersonation
    addConfig $CORE_SITE "hadoop.proxyuser.$USER.hosts" '*'
    addConfig $CORE_SITE "hadoop.proxyuser.$USER.groups" '*'

    addConfig $CORE_SITE "hadoop.http.staticuser.user" ${HADOOP_HTTP_STATICUSER_USER:="dr.who"} # hadoop
    addConfig $HDFS_SITE "dfs.checksum.combine.mode" ${DFS_CHECKSUM_COMBINE_MODE:="MD5MD5CRC"} # COMPOSITE_CRC

    : ${HA_ZOOKEEPER_QUORUM:?"HA_ZOOKEEPER_QUORUM is required."}
    addConfig $CORE_SITE "ha.zookeeper.quorum" $HA_ZOOKEEPER_QUORUM
    addConfig $CORE_SITE "ha.zookeeper.parent-znode" /$CLUSTER_NAME

    # Update hdfs-site.xml
    addConfig $HDFS_SITE "dfs.permissions.superusergroup" "hadoop"
    addConfig $HDFS_SITE "dfs.datanode.max.transfer.threads" 4096
    addConfig $HDFS_SITE "dfs.journalnode.edits.dir" ${DFS_JOURNALNODE_EDITS_DIR:="/var/lib/hadoop/journal"}

    # Create directory for journal node files
    mkdir -p $DFS_JOURNALNODE_EDITS_DIR
    chown -R hadoop:hadoop $DFS_JOURNALNODE_EDITS_DIR

    : ${DFS_NAMESERVICES:?"DFS_NAMESERVICES is required."}
    addConfig $HDFS_SITE "dfs.nameservices" $DFS_NAMESERVICES

    if [[ ${HADOOP_ROLE,,} = namenode ]]; then

        : ${DFS_HA_NAMENODE_ID:?"DFS_HA_NAMENODE_ID is required for namenodes."}
        addConfig $HDFS_SITE "dfs.ha.namenode.id" $DFS_HA_NAMENODE_ID

    elif [[ ${HADOOP_ROLE,,} = datanode ]]; then

        [ ! -z "$DFS_DATANODE_HOSTNAME" ] && \
            addConfig $HDFS_SITE "dfs.datanode.hostname" $DFS_DATANODE_HOSTNAME

    fi

    # Update core-site.xml
    # Create namenodes config
    IFS=',' read -ra DFS_NAMESERVICE <<< "$DFS_NAMESERVICES"
    for i in "${DFS_NAMESERVICE[@]}"; do

        DFS_NAMENODES_VAR=${i^^}_DFS_NAMENODES
        : ${!DFS_NAMENODES_VAR:?"${DFS_NAMENODES_VAR} is required."}

        addConfig $HDFS_SITE "dfs.ha.namenodes.${i}" ${!DFS_NAMENODES_VAR}
        addConfig $HDFS_SITE "dfs.client.failover.proxy.provider.${i}" "org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider"

        IFS=',' read -ra DFS_NAMENODE <<< "${!DFS_NAMENODES_VAR}"
        for j in "${DFS_NAMENODE[@]}"; do

            VAR=${i^^}_DFS_NAMENODE_RPC_ADDRESS_${j^^}
            : ${!VAR:?"${VAR} is required."}
            addConfig $HDFS_SITE "dfs.namenode.rpc-address.${i}.${j}" ${!VAR}
            addConfig $HDFS_SITE "dfs.namenode.rpc-bind-host.${i}.${j}" "0.0.0.0"
            addConfig $HDFS_SITE "dfs.namenode.servicerpc-bind-host.${i}.${j}" "0.0.0.0"

            VAR=${i^^}_DFS_NAMENODE_HTTP_ADDRESS_${j^^}
            : ${!VAR:?"${VAR} is required."}
            addConfig $HDFS_SITE "dfs.namenode.http-address.${i}.${j}" ${!VAR}
            addConfig $HDFS_SITE "dfs.namenode.http-bind-host.${i}.${j}" "0.0.0.0"

        done
    done

    addConfig $HDFS_SITE "dfs.client.failover.proxy.provider.${DFS_NAMESERVICE_ID}" "org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider"
    addConfig $HDFS_SITE "dfs.namenode.name.dir" ${DFS_NAMENODE_NAME_DIR:="file:///var/lib/hadoop/name"}
    addConfig $HDFS_SITE "dfs.datanode.data.dir" ${DFS_DATANODE_NAME_DIR:="file:///var/lib/hadoop/data"}
    addConfig $HDFS_SITE "dfs.replication" "${DFS_REPLICATION:-3}"
    addConfig $HDFS_SITE "dfs.blocksize" "${DFS_BLOCKSIZE:-128m}"
    addConfig $HDFS_SITE "dfs.namenode.replication.min" "${DFS_NAMENODE_REPLICATION_MIN:-1}"

    [ ! -z "$DFS_DATANODE_FSDATASET_VOLUME_CHOOSING_POLICY" ] && \
        addConfig $HDFS_SITE "dfs.datanode.fsdataset.volume.choosing.policy" "org.apache.hadoop.hdfs.server.datanode.fsdataset.AvailableSpaceVolumeChoosingPolicy"
    [ ! -z "$DFS_DATANODE_AVAILABLE_SPACE_VOLUME_CHOOSING_POLICY_BALANCED_SPACE_THRESHOLD" ] && \
        addConfig $HDFS_SITE "dfs.datanode.available-space-volume-choosing-policy.balanced-space-threshold" $DFS_DATANODE_AVAILABLE_SPACE_VOLUME_CHOOSING_POLICY_BALANCED_SPACE_THRESHOLD
    [ ! -z "$DFS_DATANODE_AVAILABLE_SPACE_VOLUME_CHOOSING_POLICY_BALANCED_SPACE_PREFRENCE_FRACTION" ] && \
        addConfig $HDFS_SITE "dfs.datanode.available-space-volume-choosing-policy.balanced-space-preference-fraction" $DFS_DATANODE_AVAILABLE_SPACE_VOLUME_CHOOSING_POLICY_BALANCED_SPACE_PREFRENCE_FRACTION

    DFS_NAMENODE_SHARED_EDITS_DIR=${DFS_NAMENODE_SHARED_EDITS_DIR//","/";"}
    addConfig $HDFS_SITE "dfs.namenode.shared.edits.dir" "qjournal://${DFS_NAMENODE_SHARED_EDITS_DIR}/${DFS_NAMESERVICE_ID}"

    addConfig $HDFS_SITE "dfs.ha.fencing.methods" "shell(/bin/true)"
    addConfig $HDFS_SITE "dfs.ha.automatic-failover.enabled" "true"

    addConfig $HDFS_SITE "dfs.client.use.datanode.hostname" "true"
    addConfig $HDFS_SITE "dfs.datanode.use.datanode.hostname" "true"
    addConfig $HDFS_SITE "dfs.namenode.datanode.registration.ip-hostname-check" "false"

    # Create and set the data directories correctly
    IFS=',' read -ra DFS_NAMENODE_NAME_DIRS <<< "$DFS_NAMENODE_NAME_DIR"
    for i in "${DFS_NAMENODE_NAME_DIRS[@]}"; do

        if [[ $i == "file:///"* ]]; then
            path=${i/"file://"/""}
            mkdir -p $path
            chmod 700 $path
            chown -R hadoop:hadoop $path
        fi
    done

    # Create and set the data directories correctly
    IFS=',' read -ra DFS_DATANODE_NAME_DIRS <<< "$DFS_DATANODE_NAME_DIR"
    for i in "${DFS_DATANODE_NAME_DIRS[@]}"; do

        if [[ $i == "file:///"* ]]; then
            path=${i/"file://"/""}
            mkdir -p $path
            chmod 700 $path
            chown -R hadoop:hadoop $path
        fi
    done

    IFS=',' read -ra HA_ZOOKEEPER_QUORUMS <<< "$HA_ZOOKEEPER_QUORUM"
    num_zk=${#HA_ZOOKEEPER_QUORUMS[*]}

    IFS=":" read -ra REMOTE_ADDR <<< "${HA_ZOOKEEPER_QUORUMS[$((RANDOM%num_zk))]}"

    if [[ ${HADOOP_ROLE,,} != console ]]; then
        until $(nc -z -v -w5 ${REMOTE_ADDR[0]} ${REMOTE_ADDR[1]}); do
            echo "Waiting for zookeeper to be available..."
            sleep 2
        done
    fi

fi

exec "$@"