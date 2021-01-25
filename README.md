# Hadoop Docker Image

## Highlights

- Supports running Hadoop (HDFS only) in distributed HA mode using journal nodes.
- Configured using environment variables.
- Multiple name service support (federations).
- Dynamic NameNode configuration via environment variables.
- Debian Stretch(9) based image

## Example

Check out the [docker-compose.yml](docker-compose.yml) file to stand up a distributed HA cluster
using docker-compose.

## TODO

- [ ] Generic environment variable configuration support
- [ ] Document environment variables.
