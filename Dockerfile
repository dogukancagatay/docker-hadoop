FROM openjdk:8u282-jdk-buster
LABEL maintainer="Doğukan Çağatay <dcagatay@gmail.com>"

ARG HADOOP_VERSION_ARG="3.3.0"

RUN apt-get update \
  && apt-get install -y locales \
  && dpkg-reconfigure -f noninteractive locales \
  && locale-gen C.UTF-8 \
  && /usr/sbin/update-locale LANG=C.UTF-8 \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Users with other locales should set this in their derivative image
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    net-tools \
    netcat \
    gnupg \
    libsnappy-dev \
    gosu \
    xmlstarlet \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV HADOOP_VERSION ${HADOOP_VERSION_ARG}
ENV HADOOP_URL "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
ENV MULTIHOMED_NETWORK 1
ENV USER=hadoop
ENV PATH ${HADOOP_HOME}/bin/:${PATH}

RUN set -x \
    && curl -O https://dist.apache.org/repos/dist/release/hadoop/common/KEYS \
    && gpg --import KEYS \
    && curl -fSL --retry 3 "${HADOOP_URL}" -o /tmp/hadoop.tar.gz \
    && curl -fSL --retry 3 "${HADOOP_URL}.asc" -o /tmp/hadoop.tar.gz.asc \
    && gpg --verify /tmp/hadoop.tar.gz.asc \
    && tar -xf /tmp/hadoop.tar.gz -C /opt/ \
    && rm /tmp/hadoop.tar.gz* \
    && ln -s /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && cp -r /opt/hadoop-${HADOOP_VERSION}/etc/hadoop /opt/hadoop-${HADOOP_VERSION}/etc/hadoop_default \
    && rm -rf ${HADOOP_HOME}/share/doc \
    && mkdir -p /opt/hadoop-${HADOOP_VERSION}/logs /var/lib/hadoop \
    && addgroup --system hadoop \
    && adduser \
        --system \
        --disabled-password \
        --no-create-home \
        --home $HADOOP_HOME \
        --ingroup hadoop \
        --shell /bin/false \
        --gecos hadoop hadoop \
    && chown -R hadoop:hadoop /opt/hadoop-${HADOOP_VERSION} \
    && chown -R hadoop:hadoop /var/lib/hadoop

COPY docker-entrypoint.sh run.sh /

VOLUME [ "/var/lib/hadoop", "/opt/hadoop/etc/hadoop" ]

#      Namenode              Datanode                     Journalnode
EXPOSE 8020 9000 50070 50470 50010 50075 50475 1006 50020 8485 8480 8481
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["/run.sh"]
