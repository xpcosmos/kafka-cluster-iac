sudo ${kafka_home}/bin/kafka-storage.sh \
  format \
  -t ${ cluster_id }\
  -c ${ kafka_home }/config/server.properties\
  --initial-controllers ${ initial_controllers }

