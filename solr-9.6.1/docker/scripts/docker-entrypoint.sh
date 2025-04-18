#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# docker-entrypoint for Solr docker

set -e

# Clear some variables that we don't want runtime
unset SOLR_USER SOLR_UID SOLR_GROUP SOLR_GID \
      SOLR_CLOSER_URL SOLR_DIST_URL SOLR_ARCHIVE_URL SOLR_DOWNLOAD_URL SOLR_DOWNLOAD_SERVER SOLR_KEYS SOLR_SHA512

if [[ "$VERBOSE" == "yes" ]]; then
    set -x
fi

if ! [[ ${SOLR_PORT:-} =~ ^[0-9]+$ ]]; then
  SOLR_PORT=8983
  export SOLR_PORT
fi

# Essential for running Solr
init-var-solr

# when invoked with e.g.: docker run solr -help
if [ "${1:0:1}" == '-' ]; then
    set -- solr-foreground "$@"
fi

#error 1cambio pq no funciono sin cmd ni con gsu en exec
# Si no se pasó ningún argumento, asignar solr-foreground por defecto
if [ "$#" -eq 0 ]; then
    set -- solr-foreground
fi

#error 2 por error en que no puede escribir log
# Asegurarse de que el directorio de logs exista y sea writable para solr
if [ ! -d /var/solr/ ]; then
    mkdir -p /var/solr/logs
fi
chown solr:solr /var/solr/*
chmod 770 /var/solr/*

# execute command passed in as arguments.
# The Dockerfile has specified the PATH to include
# /opt/solr/bin (for Solr) and /opt/solr/docker (for docker-specific scripts
# like solr-foreground, solr-create, solr-precreate, solr-demo).
# Note: if you specify "solr", you'll typically want to add -f to run it in
# the foreground.
exec gosu solr "$@"
#exec "$@"
