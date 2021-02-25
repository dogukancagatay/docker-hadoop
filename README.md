# dcagatay/hadoop

Hadoop (HDFS only) docker image with highly available and multi server deployment capability.

## Labels

- `latest`, `3.3.0`
- `3.2.2`
- `3.2.1`
- `3.1.4`
- `2.10.1`
- `2.8.2`
- `2.7.1`

[Docker hub](https://hub.docker.com/r/dcagatay/hadoop)

## Highlights

- Supports running Hadoop (HDFS only) in distributed HA mode using journal nodes.
- Configured using environment variables.
- Multiple name service support (federations).
- Dynamic NameNode configuration via environment variables.
- Debian Stretch(9) based image

## Example

Check out the [docker-compose.yml](docker-compose.yml) to stand up a distributed HA cluster
using docker-compose.

## Configuration

There are three different options here:

1. No configuration directory binding, setting just environment variables. (Suitable for just using HDFS)
1. Setting environment variables with binding `/opt/hadoop/etc/hadoop` or `/etc/hadoop` jjjdirectory w/o overwriting the `HADOOP_CONF_DIR` environment variable. (Suitable for HDFS configuration export needs. e.g. Spark)
1. Using your own configuration directory without setting confiugration items with environment variables and setting `HADOOP_CONF_DIR` to a different directory (and binding that directory) (e.g. `/config`)

## Ports

### namenode

- `8019`: `dfs.ha.zkfc.port` (IPC)
- `8020`: `fs.defaultFS` AND/OR `dfs.namenode.rpc-address.<nameservice-name>.<namenode-name>` (IPC)
- `50070`: `dfs.namenode.http-address.<nameservice-name>.<namenode-name>` (HTTP)

### datanode

- `9864`: `dfs.datanode.http.address` (HTTP)
- `9866`: `dfs.datanode.address`
- `9867`: `dfs.datanode.ipc.address` (IPC)

### journalnode

- `8480`: `dfs.journalnode.http-address` (HTTP)
- `8485`: `dfs.journalnode.rpc-address` (IPC)

## TODO

- [ ] Generic environment variable configuration support
- [ ] Document environment variables.
