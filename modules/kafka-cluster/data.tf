
data "cloudinit_config" "static" {
  gzip          = false
  base64_encode = false
  part {
    filename = "init.sh"
    content  = file("${path.module}/scripts/init.sh")
  }
  part {
    filename = "install-kafka.sh"
    content = templatefile("${path.module}/scripts/install-kafka.sh",
      {
        kafka_home = var.kafka_home
        log_dirs   = var.log_dirs
      }
    )
  }

  part {
    filename = "setup-kafka-storage.sh"
    content = templatefile("${path.module}/scripts/setup-kafka-storage.sh",
      {
        kafka_home                       = var.kafka_home
        initial_controllers              = local.initial_controllers
        kafka_server_properties_filename = local.kafka_server_properties_filename
        cluster_id                       = random_uuid.kafka_cluster_id.id
      }
    )
  }

  part {
    filename = "setup-prometheus.sh"
    content = templatefile("${path.module}/scripts/setup-prometheus.sh",
      {
        prometheus_properties_filename = local.prometheus_properties_filename
        prometheus_properties_content  = file("${path.module}/prometheus/kafka_config.yml")
      }
    )
  }
  part {
    filename = "setup-kafka-redis-connect.sh"
    content = templatefile("${path.module}/scripts/setup-kafka-redis-connect.sh",
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
    )
  }
}





data "cloudinit_config" "dynamic" {

  gzip          = false
  base64_encode = false
  for_each      = toset(local.brokers)

  # TODO Adicionar properties servidor kafka
  part {
    filename = "setup-kafka.sh"
    content = templatefile("${path.module}/scripts/setup-kafka.sh",
      {
        kafka_server_properties_filename = local.kafka_server_properties_filename
        kafka_server_properties_content = templatefile("${path.module}/properties/server.properties.tftpl",
          {
            node_id                  = each.key
            log_dirs                 = var.log_dirs
            partitions_num           = var.partitions_num
            broker_name              = each.value
            broker                   = var.broker
            controller               = var.controller
            quorum_bootstrap_servers = local.quorum_bootstrap_servers
          }
        )
      }
    )
  }
  part {
    filename     = "start-server.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/scripts/start-server.sh",

      {
        kafka_home        = var.kafka_home
        bootstrap_servers = local.bootstrap_servers
        topics            = var.topics
        broker_name       = each.value

        kafka_server_properties_filename = local.kafka_server_properties_filename
        redis_sink_properties_filename   = local.redis_sink_properties_filename
        prometheus_properties_filename   = local.prometheus_properties_filename
        connector_properties_filename    = local.connector_properties_filename
        redis_sink                       = var.redis_sink

      }
    )
  }
}


data "cloudinit_config" "metadata_startup_script" {
  gzip          = false
  base64_encode = false
  for_each = data.cloudinit_config.dynamic
  part {
    content = data.cloudinit_config.static.rendered
  }
  part {
    content = each.value.rendered
  }
}
