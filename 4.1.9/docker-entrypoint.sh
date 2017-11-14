#!/usr/bin/env bash
set -e

INIT=false
EXISTING=false
USAGE=false
VERBOSE=false
RUN_IRODS=false

_update_uid_gid() {
    # update UID
    gosu root usermod -u ${UID_IRODS} irods
    # update GID
    gosu root groupmod -g ${GID_IRODS} irods
    # update directories
    gosu root chown -R irods:irods /var/lib/irods
    gosu root chown -R irods:irods /etc/irods
}

_irods_tgz() {
    if [ -z "$(ls -A /var/lib/irods)" ]; then
        gosu root cp /irods.tar.gz /var/lib/irods/irods.tar.gz
        cd /var/lib/irods/
        if $VERBOSE; then
            echo "!!! populating /var/lib/irods with initial contents !!!"
            gosu root tar -zxvf irods.tar.gz
        else
            gosu root tar -zxf irods.tar.gz
        fi
        cd /
        gosu root rm -f /var/lib/irods/irods.tar.gz
    fi
    if [ -z "$(ls -A /etc/irods)" ]; then
        gosu root cp /etc_irods.tar.gz /etc/irods/etc_irods.tar.gz
        cd /etc/irods/
        if $VERBOSE; then
            echo "!!! populating /etc/irods with initial contents !!!"
            gosu root tar -zxvf etc_irods.tar.gz
        else
            gosu root tar -zxf etc_irods.tar.gz
        fi
        cd /
        gosu root rm -f /etc/irods/etc_irods.tar.gz
    fi
}

_generate_config() {
    local OUTFILE=/irods.config
    echo "${IRODS_SERVICE_ACCOUNT_NAME}" > $OUTFILE
    echo "${IRODS_SERVICE_ACCOUNT_GROUP}" >> $OUTFILE
    echo "${IRODS_PORT}" >> $OUTFILE
    echo "${IRODS_PORT_RANGE_BEGIN}" >> $OUTFILE
    echo "${IRODS_PORT_RANGE_END}" >> $OUTFILE
    echo "${IRODS_VAULT_DIRECTORY}" >> $OUTFILE
    echo "${IRODS_SERVER_ZONE_KEY}" >> $OUTFILE
    echo "${IRODS_SERVER_NEGOTIATION_KEY}" >> $OUTFILE
    echo "${IRODS_CONTROL_PLANE_PORT}" >> $OUTFILE
    echo "${IRODS_CONTROL_PLANE_KEY}" >> $OUTFILE
    echo "${IRODS_SCHEMA_VALIDATION}" >> $OUTFILE
    echo "${IRODS_SERVER_ADMINISTRATOR_USER_NAME}" >> $OUTFILE
    echo "yes" >> $OUTFILE
    echo "${IRODS_PROVIDER_HOST_NAME}" >> $OUTFILE
    echo "${IRODS_PROVIDER_ZONE_NAME}" >> $OUTFILE
    echo "yes" >> $OUTFILE
    echo "${IRODS_SERVER_ADMINISTRATOR_PASSWORD}" >> $OUTFILE
#    echo "${IRODS_SERVER_ROLE}" >> $OUTFILE
}

_usage() {
    echo "Usage: ${0} [-h] [-ix run_irods] [-v] [arguments]"
    echo ""
    echo "options:"
    echo "-h                    show brief help"
    echo "-i run_irods          initialize iRODS 4.1.9 consumer"
    echo "-x run_irods          use existing iRODS 4.1.9 consumer files"
    echo "-v                    verbose output"
    echo ""
    echo "Example:"
    echo "  $ docker run --rm mjstealey/irods-consumer:4.1.9 -h           # show help"
    echo "  $ docker run -d mjstealey/irods-consumer:4.1.9 -i run_irods   # init with default settings"
    echo ""
    exit 0
}

while getopts hixv opt; do
  case "${opt}" in
    h)      USAGE=true ;;
    i)      INIT=true && echo "INFO: Initialize iRODS consumer";;
    x)      EXISTING=true && echo "INFO: Use existing iRODS consumer files";;
    v)      VERBOSE=true ;;
    ?)      USAGE=true && echo "ERROR: Invalid option provided";;
  esac
done

for var in "$@"
do
    if [[ "${var}" = 'run_irods' ]]; then
        RUN_IRODS=true
    fi
done

if $RUN_IRODS; then
    if $USAGE; then
        _usage
    fi
    if $INIT; then
        _irods_tgz
        _update_uid_gid
        _generate_config
        gosu root /var/lib/irods/packaging/setup_irods.sh < /irods.config
        _update_uid_gid
        if $VERBOSE; then
            echo "INFO: show ienv"
            gosu irods ienv
        fi
        gosu root tail -f /dev/null
    fi
    if $EXISTING; then
        _update_uid_gid
        gosu root service irods start
        gosu root tail -f /dev/null
    fi
else
    if $USAGE; then
        _usage
    fi
    _update_uid_gid
    exec "$@"
fi

exit 0;