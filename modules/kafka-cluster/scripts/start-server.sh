export TIME_TO_RETRY=2

%{for key, value in services~}
sudo cat << 'SERVICE' > /etc/systemd/system/${key}.service
${ value }
SERVICE
sudo systemctl daemon-reload
sudo systemctl enable ${key} --now
sudo systemctl start ${key}

%{endfor~}

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
    "topics": "${topics}",
    "redis.uri": "redis://${redis_sink.host}:${redis_sink.port}",
    "redis.type": "JSON",
    "redis.command": "JSONSET",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "key.converter.schemas.enable": "false"
  }
}
REQUEST

