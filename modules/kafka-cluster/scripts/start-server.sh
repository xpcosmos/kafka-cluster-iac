sudo KAFKA_OPTS="-javaagent:/jmx_prometheus_javaagent-1.5.0.jar=8091:${prometheus_properties_path}" ${kafka_home}/bin/kafka-server-start.sh -daemon $PATH_SERVER_PROPERTIES
sudo ${kafka_home}/bin/kafka-topics.sh --bootstrap-server ${bootstrap_servers} --create --topic ${topics}

export TIME_TO_RETRY=2


sudo ${kafka_home}/bin/connect-distributed.sh -daemon  ${connector_properties_path} ${redis_sink_properties_path}


while [ "$(curl -o /dev/null -s -w '%%{http_code}' http://${broker_name}:8083/connectors)" -ne 200 ]
do
  sleep $TIME_TO_RETRY
  (( TIME_TO_RETRY *= 2 ))
done

sudo curl -X POST http://${broker_name}:8083/connectors \
  -H "Content-Type: application/json" \
  -w "\n" \
  --data @- << 'REQUEST'
{
  "name": "RedisKafkaSinkConnector",
  "config": {
    "connector.class": "com.redis.kafka.connect.RedisSinkConnector",
    "tasks.max": "1",
    "topics": "teste",
    "redis.uri": "redis://redis:6379",
    "redis.type": "JSON",
    "redis.command": "JSONSET",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "key.converter.schemas.enable": "false"
  }
}
REQUEST

