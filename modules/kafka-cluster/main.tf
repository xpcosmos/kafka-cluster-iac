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
  redis_sink_properties_filename   = "${var.kafka_home}/config/redis-sink.properties"
  connector_properties_filename    = "${var.kafka_home}/config/connect.properties"
  kafka_server_properties_filename = "${var.kafka_home}/config/kafka-server.properties"
  prometheus_properties_filename   = "/prometheus/rules/kafka_config.yml"
}

locals {

  services = {

    kafka_connect = templatefile("${path.module}/services/kafka-connect.service",
      {
        kafka_home                     = var.kafka_home
        connector_properties_filename  = local.connector_properties_filename
        redis_sink_properties_filename = local.redis_sink_properties_filename
      }
    )
    kafka_server = templatefile("${path.module}/services/kafka-server.service",
      {
        kafka_home                       = var.kafka_home
        kafka_server_properties_filename = local.kafka_server_properties_filename
        prometheus_properties_filename   = local.prometheus_properties_filename
      }
    )
    kafka_server = templatefile("${path.module}/services/kafka-create-topic.service",
      {
        kafka_home        = var.kafka_home
        bootstrap_servers = local.bootstrap_servers
        topics            = var.topics
      }
    )

  }


}

locals {
  configs = {
    for key, broker_name in local.brokers : broker_name => join("\n",
      [
        file("${path.module}/scripts/init.sh"),
        templatefile("${path.module}/scripts/install-kafka.sh",
          {
            kafka_home = var.kafka_home
            log_dirs   = var.log_dirs
          }
        )
        ,
        templatefile("${path.module}/scripts/setup-prometheus.sh",
          {
            prometheus_properties_filename = local.prometheus_properties_filename
            prometheus_properties_content  = file("${path.module}/prometheus/kafka_config.yml")
          }
        ),
        templatefile("${path.module}/scripts/setup-kafka-redis-connect.sh",
          {
            redis_sink_properties_filename = local.redis_sink_properties_filename
            redis_sink_properties_content  = templatefile("${path.module}/properties/redis-sink.properties.tftpl", merge(var.redis_sink, { topics = var.topics }))
            connector_properties_filename  = local.connector_properties_filename
            connector_properties_content = templatefile("${path.module}/properties/connect.properties.tftpl",
              {
                bootstrap_servers = local.bootstrap_servers
                group_id          = var.connect.group_id
              }
            )
          }
        ),
        templatefile("${path.module}/scripts/setup-kafka.sh",
          {
            kafka_server_properties_filename = local.kafka_server_properties_filename
            kafka_server_properties_content = templatefile("${path.module}/properties/server.properties.tftpl",
              {
                node_id                  = key
                broker_name              = broker_name
                log_dirs                 = var.log_dirs
                partitions_num           = var.partitions_num
                broker                   = var.broker
                controller               = var.controller
                quorum_bootstrap_servers = local.quorum_bootstrap_servers
              }
            )
          }
        ),
        templatefile("${path.module}/scripts/setup-kafka-storage.sh",
          {
            kafka_home                       = var.kafka_home
            initial_controllers              = local.initial_controllers
            kafka_server_properties_filename = local.kafka_server_properties_filename
            cluster_id                       = random_uuid.kafka_cluster_id.id
          }
        ),
        templatefile("${path.module}/scripts/start-server.sh",

          {
            kafka_home        = var.kafka_home
            bootstrap_servers = local.bootstrap_servers
            topics            = var.topics
            broker_name       = broker_name
            redis_sink        = var.redis_sink
            services          = local.services
          }
        )
      ]
    )
  }




}
