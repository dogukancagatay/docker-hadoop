FROM debian:stretch

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openjdk-8-jdk \
      net-tools \
      curl \
      netcat \
      gnupg \
      libsnappy-dev \
      gosu \
      xmlstarlet \
    && rm -rf /var/lib/apt/lists/*

ENV HADOOP_VERSION 3.2.2
ENV JAVA_HOME "/usr/lib/jvm/java-8-openjdk-amd64/"
ENV HADOOP_URL "https://www.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz"

RUN curl -O https://dist.apache.org/repos/dist/release/hadoop/common/KEYS && \
    gpg --import KEYS

RUN set -x \
    && curl -fSL "$HADOOP_URL" -o /tmp/hadoop.tar.gz \
    && curl -fSL "$HADOOP_URL.asc" -o /tmp/hadoop.tar.gz.asc \
    && gpg --verify /tmp/hadoop.tar.gz.asc \
    && tar -xf /tmp/hadoop.tar.gz -C /opt/ \
    && rm /tmp/hadoop.tar.gz*

RUN ln -s /opt/hadoop-$HADOOP_VERSION /opt/hadoop && \
    ln -s /opt/hadoop-$HADOOP_VERSION/etc/hadoop /etc/hadoop && \
    mkdir -p /opt/hadoop-$HADOOP_VERSION/logs /hadoop-data /var/lib/hadoop

ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
ENV MULTIHOMED_NETWORK=1
ENV USER=hadoop
ENV PATH ${HADOOP_HOME}/bin/:${PATH}

# Set up permissions
RUN addgroup --system hadoop && \
 adduser --system --disabled-password --no-create-home --home $HADOOP_HOME --ingroup hadoop --shell /bin/false --gecos hadoop hadoop && \
 chown -R hadoop:hadoop /opt/hadoop-$HADOOP_VERSION && \
 chown -R hadoop:hadoop /var/lib/hadoop /hadoop-data

COPY docker-entrypoint.sh run-hadoop.sh /
RUN chmod +x /run-hadoop.sh /docker-entrypoint.sh

#      Namenode              Datanode                     Journalnode
EXPOSE 8020 9000 50070 50470 50010 50075 50475 1006 50020 8485 8480 8481
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["/run-hadoop.sh"]
