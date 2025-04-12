ARG BASE_IMAGE=eclipse-temurin:17-jre-jammy

FROM $BASE_IMAGE

#COPY /server /opt/
#COPY /bin /opt/
#COPY /modules /opt/
#COPY /scripts /opt/
COPY / /opt


ARG SOLR_VERSION="9.6.1"


LABEL org.opencontainers.image.title="Apache Solr"
LABEL org.opencontainers.image.description="Apache Solr is the popular, blazing-fast, open source search platform built on Apache Lucene."
LABEL org.opencontainers.image.authors="The Apache Solr Project"
LABEL org.opencontainers.image.url="https://solr.apache.org"
LABEL org.opencontainers.image.source="https://github.com/apache/solr"
LABEL org.opencontainers.image.documentation="https://solr.apache.org/guide/"
LABEL org.opencontainers.image.version="${SOLR_VERSION}"
LABEL org.opencontainers.image.licenses="Apache-2.0"

ENV SOLR_USER="solr" \
    SOLR_UID="8983" \
    SOLR_GROUP="solr" \
    SOLR_GID="8983" \
    PATH="/opt/solr/bin:/opt/solr/docker/scripts:/opt/solr/prometheus-exporter/bin:$PATH" \
    SOLR_INCLUDE=/etc/default/solr.in.sh \
    SOLR_HOME=/var/solr/data \
    SOLR_PID_DIR=/var/solr \
    SOLR_LOGS_DIR=/var/solr/logs \
    LOG4J_PROPS=/var/solr/log4j2.xml \
    SOLR_JETTY_HOST="0.0.0.0" \
    SOLR_ZK_EMBEDDED_HOST="0.0.0.0"\
    SOLR_JAVA_MEM="-XX:+UseSerialGC -Xms128m -Xmx128m"

RUN set -ex; \
    groupadd -r --gid "$SOLR_GID" "$SOLR_GROUP"; \
    useradd -r --uid "$SOLR_UID" --gid "$SOLR_GID" "$SOLR_USER"

# add symlink to /opt/solr, remove what we don't want.
# Remove the Dockerfile because it might not represent the dockerfile that was used to generate the image.
RUN set -ex; \
    (cd /opt; ln -s solr-*/ solr); \
    rm -Rf /opt/solr/docs /opt/solr/docker/Dockerfile;



RUN set -ex; \
    mkdir -p /opt/solr/server/solr/lib /docker-entrypoint-initdb.d; \
    cp /opt/solr/bin/solr.in.sh /etc/default/solr.in.sh; \
    mv /opt/solr/bin/solr.in.sh /opt/solr/bin/solr.in.sh.orig; \
    mv /opt/solr/bin/solr.in.cmd /opt/solr/bin/solr.in.cmd.orig; \
    chmod 0664 /etc/default/solr.in.sh; \
    mkdir -p -m0770 /var/solr; \
    chown -R "$SOLR_USER:0" /var/solr; \
    test ! -e /opt/solr/modules || ln -s /opt/solr/modules /opt/solr/contrib; \
    test ! -e /opt/solr/prometheus-exporter || ln -s /opt/solr/prometheus-exporter /opt/solr/modules/prometheus-exporter;

RUN set -ex; \
    apt-get update; \
    apt-get -y --no-install-recommends install acl lsof procps wget netcat gosu tini jattach; \
    rm -rf /var/lib/apt/lists/*;


#VOLUME /var/solr
EXPOSE 8983
WORKDIR /opt/solr

USER root
RUN find /var/solr -mindepth 1 -maxdepth 1 ! -name "lost+found" -exec chown -R "$SOLR_USER:$SOLR_GROUP" {} + && \
    find /var/solr -mindepth 1 -maxdepth 1 ! -name "lost+found" -exec chmod -R 770 {} +

RUN chmod +x /opt/solr/bin/* /opt/solr/docker/scripts/* /opt/solr/server/*
RUN ls -l /opt/solr/server/solr/discursos
RUN ls -l /var/solr/

COPY ./solr-9.6.1/server/solr/Topics/conf/ /var/solr/data/Topics
COPY ./solr-9.6.1/server/solr/Topics/core.properties /var/solr/data/Topics
COPY ./solr-9.6.1/server/solr/discursos/conf/ /var/solr/data/discursos
COPY ./solr-9.6.1/server/solr/discursos/core.properties /var/solr/data/discursos
#RUN chown -R solr:solr /var/solr/* && chmod -R 770 /var/solr/*

USER $SOLR_UID

ENTRYPOINT ["docker-entrypoint.sh"]
#CMD ["solr-foreground"]
