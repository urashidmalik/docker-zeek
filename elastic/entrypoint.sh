#!/bin/sh

set -euo pipefail

ELASTICSEARCH_HOSTS=${ELASTICSEARCH_HOSTS:-elasticsearch:9200}
KIBANA_HOST=${ELASTICSEARCH_HOSTS:-kibana:5601}

# Wait for elasticsearch to start. It requires that the status be either
# green or yellow.
waitForElasticsearch() {
  echo -n "===> Waiting on elasticsearch(${ELASTICSEARCH_HOSTS}) to start..."
  i=0;
  while [ $i -le 60 ]; do
    health=$(curl --silent "${ELASTICSEARCH_HOSTS}/_cat/health" | awk '{print $4}')
    if [[ "$health" == "green" ]] || [[ "$health" == "yellow" ]]
    then
      echo
      echo "Elasticsearch is ready!"
      return 0
    fi

    echo -n '.'
    sleep 1
    i=$((i+1));
  done

  echo
  echo >&2 'Elasticsearch is not running or is not healthy.'
  echo >&2 "Address: ${ELASTICSEARCH_HOSTS}"
  echo >&2 "$health"
  exit 1
}

# Wait for. Params: host, port, service
waitFor() {
    echo -n "===> Waiting for ${2}(${1}) to start..."
    i=1
    while [ $i -le 20 ]; do
        if nc -vz ${1} 2>/dev/null; then
            echo "${2} is ready!"
            return 0
        fi

        echo -n '.'
        sleep 1
        i=$((i+1))
    done

    echo
    echo >&2 "${2} is not available"
    echo >&2 "Address: ${1}"
}

startFilebeat() {
    cd /usr/share/filebeat
    filebeat setup
    filebeat &
}

if [[ -z $1 ]] || [[ ${1:0:1} == '-' ]] ; then
  waitForElasticsearch
  waitFor ${KIBANA_HOST} Kibana
  startFilebeat
  cd /pcap
  exec bro "$@"
fi

exec "$@"