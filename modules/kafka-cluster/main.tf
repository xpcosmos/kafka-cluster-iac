# Definicao de ID de cluster
resource "random_uuid" "kafka_cluster_id" {}

# Definicao de UUID para diretorios
resource "random_bytes" "uuid_binary" {
  count  = var.cluster_size
  length = 16
}

locals {
  brokers = [
    for i in range(var.cluster_size) :
    "kafka-broker-${i}"
  ]

  dir_id = [
    for i in random_bytes.uuid_binary :
    replace(
      replace(
        replace(i.base64, "+", "-"),
        "/", "_"
      ),
      "=", ""
    )
  ]
}

locals {
  quorum_bootstrap_servers = [for i in local.brokers : "${i}:${var.controller.port}"]
  bootstrap_servers        = [for i in local.brokers : "${i}:${var.broker.port}"]
  initial_controllers = [
    for broker, id in zipmap(local.brokers, local.dir_id) :
    "${index(local.brokers, broker)}@${broker}:${var.controller.port}:${id}"
  ]
}

locals {
  redis_sink_properties_filename = "${var.kafka_home}/config/redis-sink.properties"
  connector_properties_filename = "${var.kafka_home}/config/connect.properties"
  kafka_server_properties_filename = "${var.kafka_home}/config/kafka-server.properties"
  prometheus_properties_filename = "/prometheus/rules/kafka_config.yml"
}
