# dcagatay/hadoop

Hadoop (HDFS only) docker image with highly available and multi server deployment capability.

## Highlights

- Supports running Hadoop (HDFS only) in distributed HA mode using journal nodes.
- Configured using environment variables.
- Multiple name service support (federations).
- Dynamic NameNode configuration via environment variables.
- Debian Stretch(9) based image

## Example

Check out the [docker-compose.yml](docker-compose.yml) to stand up a distributed HA cluster
using docker-compose.

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
