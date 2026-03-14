sudo ${kafka_home}/bin/kafka-storage.sh \
  format \
  -t ${ cluster_id }\
  -c ${ kafka_server_properties_filename }\
  --initial-controllers ${ join(",", initial_controllers) }

