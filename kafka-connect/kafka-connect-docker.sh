#!/bin/bash

kc_cfg_file="/etc/kafka-connect/kafka-connect.properties"

export KAFKA_CONNECT_REST_PORT=${KAFKA_CONNECT_REST_PORT:=8083}
export KAFKA_CONNECT_CLIENT_ID=${KAFKA_CONNECT_CLIENT_ID:=$HOSTNAME}

export KAFKA_CONNECT_BOOTSTRAP_SERVERS=${KAFKA_CONNECT_BOOTSTRAP_SERVERS:=$KAFKA_PORT_9092_TCP_ADDR:$KAFKA_PORT_9092_TCP_PORT}
export KAFKA_CONNECT_GROUP_ID=${KAFKA_CONNECT_GROUP_ID:=connect-cluster}
export KAFKA_CONNECT_KEY_CONVERTER=${KAFKA_CONNECT_KEY_CONVERTER:=io.confluent.connect.avro.AvroConverter}
export KAFKA_CONNECT_VALUE_CONVERTER=${KAFKA_CONNECT_VALUE_CONVERTER:=io.confluent.connect.avro.AvroConverter}

export KAFKA_CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL=${KAFKA_CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL:=http://$SCHEMA_REGISTRY_PORT_8081_TCP_ADDR:$SCHEMA_REGISTRY_PORT_8081_TCP_PORT}
export KAFKA_CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL=${KAFKA_CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL:=http://$SCHEMA_REGISTRY_PORT_8081_TCP_ADDR:$SCHEMA_REGISTRY_PORT_8081_TCP_PORT}

export KAFKA_CONNECT_INTERNAL_KEY_CONVERTER=${KAFKA_CONNECT_INTERNAL_KEY_CONVERTER:=org.apache.kafka.connect.json.JsonConverter}
export KAFKA_CONNECT_INTERNAL_VALUE_CONVERTER=${KAFKA_CONNECT_INTERNAL_VALUE_CONVERTER:=org.apache.kafka.connect.json.JsonConverter}
export KAFKA_CONNECT_INTERNAL_KEY_CONVERTER_SCHEMAS_ENABLE=${KAFKA_CONNECT_INTERNAL_KEY_CONVERTER_SCHEMAS_ENABLE:=false}
export KAFKA_CONNECT_INTERNAL_VALUE_CONVERTER_SCHEMAS_ENABLE=${KAFKA_CONNECT_INTERNAL_VALUE_CONVERTER_SCHEMAS_ENABLE:=false}

export KAFKA_CONNECT_CONFIG_STORAGE_TOPIC=${KAFKA_CONNECT_CONFIG_STORAGE_TOPIC:=connect-configs}
export KAFKA_CONNECT_OFFSET_STORAGE_TOPIC=${KAFKA_CONNECT_OFFSET_STORAGE_TOPIC:=connect-offsets}

# Download the config file, if given a URL
if [ ! -z "$KC_CFG_URL" ]; then
  echo "[KC] Downloading KC config file from ${KC_CFG_URL}"
  curl --location --silent --insecure --output ${kc_cfg_file} ${KC_CFG_URL}
  if [ $? -ne 0 ]; then
    echo "[KC] Failed to download ${KC_CFG_URL} exiting."
    exit 1
  fi
fi

echo '# Generated by kafka-connect-docker.sh' > ${kc_cfg_file}
for var in $(env | grep '^KAFKA_CONNECT_' | sort); do
  key=$(echo $var | sed -r 's/KAFKA_CONNECT_(.*)=.*/\1/g' | tr A-Z a-z | tr _ .)
  value=$(echo $var | sed -r 's/.*=(.*)/\1/g')
  echo "${key}=${value}" >> ${kc_cfg_file}
done

chown -R "${CONFLUENT_USER}:${CONFLUENT_GROUP}" "${kc_cfg_file}"

/bin/gosu "${CONFLUENT_USER}:${CONFLUENT_GROUP}" /usr/bin/connect-distributed "${kc_cfg_file}" "$@"