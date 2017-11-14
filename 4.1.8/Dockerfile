FROM debian:jessie
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

RUN set -ex; \
    if ! command -v gpg > /dev/null; then \
        apt-get update; \
        apt-get install -y --no-install-recommends \
        gnupg \
        dirmngr \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi

# set user/group IDs for irods account
RUN groupadd -r irods --gid=998 \
    && useradd -r -g irods -d /var/lib/irods --uid=998 irods

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.10
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove ca-certificates wget

# Prerequisites for iRODS v.4.1.8
RUN apt-get update && apt-get install -y \
    apt-utils \
    sudo \
    curl \
    libfuse2 \
    libjson-perl \
    python-psutil \
    python-requests \
    lsof \
    python-jsonschema

# Install iRODS v.4.1.8
RUN curl ftp://ftp.renci.org/pub/irods/releases/4.1.8/ubuntu14/irods-resource-4.1.8-ubuntu14-x86_64.deb -o irods-resource.deb \
    && sudo dpkg -i irods-resource.deb \
    && sudo apt-get -f install \
    && rm irods-resource.deb

# default iRODS env
ENV IRODS_SERVICE_ACCOUNT_NAME=irods
ENV IRODS_SERVICE_ACCOUNT_GROUP=irods
ENV IRODS_PROVIDER_ZONE_NAME=tempZone
ENV IRODS_PROVIDER_HOST_NAME=provider
ENV IRODS_PORT=1247
ENV IRODS_PORT_RANGE_BEGIN=20000
ENV IRODS_PORT_RANGE_END=20199
ENV IRODS_CONTROL_PLANE_PORT=1248
ENV IRODS_SCHEMA_VALIDATION=https://schemas.irods.org/configuration
ENV IRODS_SERVER_ADMINISTRATOR_USER_NAME=rods
ENV IRODS_SERVER_ZONE_KEY=TEMPORARY_zone_key
ENV IRODS_SERVER_NEGOTIATION_KEY=TEMPORARY_32byte_negotiation_key
ENV IRODS_CONTROL_PLANE_KEY=TEMPORARY__32byte_ctrl_plane_key
ENV IRODS_SERVER_ADMINISTRATOR_PASSWORD=rods
ENV IRODS_VAULT_DIRECTORY=/var/lib/irods/iRODS/Vault
# UID / GID settings
ENV UID_IRODS=998
ENV GID_IRODS=998

# create irods.tar.gz
RUN cd /var/lib/irods \
    && tar -czvf /irods.tar.gz . \
    && cd /

# create etc_irods.tar.gz
RUN cd /etc/irods \
    && tar -czvf /etc_irods.tar.gz . \
    && cd /

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
VOLUME /var/lib/irods /etc/irods

EXPOSE $IRODS_PORT $IRODS_CONTROL_PLANE_PORT $IRODS_PORT_RANGE_BEGIN-$IRODS_PORT_RANGE_END
ENTRYPOINT ["/docker-entrypoint.sh"]
WORKDIR "/var/lib/irods"

CMD ["-i", "run_irods"]