#!/bin/bash

CONNECT_PORT=${CONNECT_PORT:-8083}
FORWARDLOGS="${FORWARDLOGS:-1}"
# LOGS=(broker schema-registry rest-proxy connect-distributed zookeeper)
LOGS=(broker)

if [[ "$FORWARDLOGS" == "0" ]]; then
    echo "Skipping sinking logs to kafka  due to \$FORWARDLOGS = 0."
    exit 0
fi

for (( i=0; i<${#LOGS[@]}; i++)); do
cat <<EOF >/tmp/connector
{
  "name": "logs-${LOGS[$i]}",
  "config": {
    "connector.class": "org.apache.kafka.connect.file.FileStreamSourceConnector",
    "tasks.max": "1",
    "topic": "logs_${LOGS[$i]}",
    "file":"/var/log/${LOGS[$i]}.log"
  }
}
EOF

    curl -vs --stderr - -X POST -H "Content-Type: application/json" \
         --data @/tmp/connector "http://localhost:$CONNECT_PORT/connectors"
done

rm /tmp/connector
