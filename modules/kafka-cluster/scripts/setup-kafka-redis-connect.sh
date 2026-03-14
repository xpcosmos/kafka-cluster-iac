# Redis Kafka Connect
sudo wget https://hub-downloads.confluent.io/api/plugins/redis/redis-kafka-connect/versions/0.9.1/redis-redis-kafka-connect-0.9.1.zip

# Unzip de Kafka Connect
sudo unzip redis-redis-kafka-connect-0.9.1.zip
sudo mv /redis-redis-kafka-connect-0.9.1/lib/ /libs/

cat << REDIS > ${kafka_home}/config/
${ redis_sink_properties_content }
REDIS

cat << CONNECTOR_STANDALONE > ${connector_properties_path}
${ connector_properties_content }
CONNECTOR_STANDALONE