#!/bin/bash

############################## Instalacao de pacotes ##############################

sudo apt update
sudo apt install -y default-jdk unzip

############################# Configurações servidor ##############################

export KAFKA_HOME="/opt/kafka"

# Arquivo de configuração a ser modificado
export SERVER_PROPERTIES="$KAFKA_HOME/config/server.properties"

# Arquivo de configuracao para conectores
export CONNECTORS_PROPERTIES="$KAFKA_HOME/config/connect-standalone.properties"
export REDIS_SINK_PROPERTIES="$KAFKA_HOME/config/redis-skin.properties"


# Nome de instancia sendo confidurada. Indice é definida
# no arquivo `compute_engine.tf` e exportada para o contexto
export KAFKA_BROKER_NAME="kafka-broker-${KAFKA_INSTANCE_NUM}"

# Local do arquivo de log
export LOG_DIRS="/var/kafka"

# Definicao de valor `advertised.listeners`
export ADVERTISED_LISTENERS="PLAINTEXT://$KAFKA_BROKER_NAME:9092"

# Definicao de valor `listeners`
export LISTENERS="PLAINTEXT://$KAFKA_BROKER_NAME:9092,CONTROLLER://$KAFKA_BROKER_NAME:9093"



################################ Instalacao Kafka #################################

# Download e extracao do Kafka
sudo wget https://dlcdn.apache.org/kafka/4.1.1/kafka_2.13-4.1.1.tgz
sudo tar -xzf /kafka_2.13-4.1.1.tgz
sudo mv /kafka_2.13-4.1.1 $KAFKA_HOME
sudo rm -rf /kafka_2.13-4.1.1.tgz

# Criacao de pastas e ajustes de permissoes
sudo mkdir -p $LOG_DIRS
sudo chown -R $USER:$USER $LOG_DIRS

########################### Modificacao de parametros #############################

# Scripts para substituição de parametros em arquivo de propriedade

sudo sed -i -e "s\
|node.id=1\
|node.id=$KAFKA_INSTANCE_NUM\
|g" $SERVER_PROPERTIES

sudo sed -i -e "s\
|controller.quorum.bootstrap.servers=localhost:9093\
|controller.quorum.bootstrap.servers=$CONTROLLER_QUORUM_BOOTSTRAP_SERVERS\
|g" $SERVER_PROPERTIES


sudo sed -i -e "s\
|listeners=PLAINTEXT://:9092,CONTROLLER://:9093\
|listeners=$LISTENERS\
|g" $SERVER_PROPERTIES

sudo sed -i -e "s\
|log.dirs=/tmp/kraft-combined-logs\
|log.dirs="$LOG_DIRS/data"\
|g" $SERVER_PROPERTIES


sudo sed -i -e "s\
|advertised.listeners=PLAINTEXT://localhost:9092,CONTROLLER://localhost:9093\
|advertised.listeners=$ADVERTISED_LISTENERS\
|g" $SERVER_PROPERTIES

sudo sed -i -e "s\
|num.partitions=1\
|num.partitions=$KAFKA_NUM_PARTITIONS\
|g" $SERVER_PROPERTIES

sudo sed -i -e "$a\cleanup.policy=compact" $SERVER_PROPERTIES

############################# Configuracao de Storage #############################

# O atributo `KAFKA_CLUSTER_ID` e `INITIAL_CONTROLLERS` sao definidos no arquivo
# `compute_engine.tf`. Os valores de ID sao setados pelo terraform e compartilhados
# entre os nos
sudo $KAFKA_HOME/bin/kafka-storage.sh \
  format \
  -t $KAFKA_CLUSTER_ID \
  -c $SERVER_PROPERTIES \
  --initial-controllers $INITIAL_CONTROLLERS

############################ Inicializacao de servidor ############################

sudo $KAFKA_HOME/bin/kafka-server-start.sh -daemon $SERVER_PROPERTIES
[ $KAFKA_INSTANCE_NUM -eq "1" ] && sudo /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker-1:9092 --create --topic teste

############################ Instalacao Kafka Connect #############################

sudo wget https://hub-downloads.confluent.io/api/plugins/redis/redis-kafka-connect/versions/0.9.1/redis-redis-kafka-connect-0.9.1.zip
sudo unzip redis-redis-kafka-connect-0.9.1.zip
sudo mv /redis-redis-kafka-connect-0.9.1/lib/ /libs/

sudo sed -i -e "s\
|bootstrap.servers=localhost:9092\
|bootstrap.servers=$BOOTSTRAP_SERVERS\
|g" $CONNECTORS_PROPERTIES

sudo sed -i -e "s\
|key.converter=org.apache.kafka.connect.json.JsonConverter\
|key.converter=org.apache.kafka.connect.storage.StringConverter\
|g" $CONNECTORS_PROPERTIES

sudo sed -i -e "s\
|.converter.schemas.enable=true\
|.converter.schemas.enable=false\
|g" $CONNECTORS_PROPERTIES

sudo bash -c "echo 'plugin.path=/libs' >> $CONNECTORS_PROPERTIES"

cat << REDIS > $REDIS_SINK_PROPERTIES

############################# Configuracoes Gerais #############################

name=RedisKafkaSinkConnector
connector.class=com.redis.kafka.connect.RedisSinkConnector
redis.server.mode=Standalone
topics=teste
redis.database=0
redis.timeout=60

#################################### Rede ######################################

redis.host=redis
redis.port=6379
redis.uri=redis://redis:6379

################################ Key & Value ####################################

key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
value.converter.schemas.enable=false

redis.command=JSONSET

transforms=createKey,extractKey
transforms.createKey.type=org.apache.kafka.connect.transforms.ValueToKey
transforms.createKey.fields=driver_id

transforms.extractKey.type=org.apache.kafka.connect.transforms.ExtractField\$Key
transforms.extractKey.field=driver_id
REDIS

sudo $KAFKA_HOME/bin/connect-standalone.sh $CONNECTORS_PROPERTIES $REDIS_SINK_PROPERTIES