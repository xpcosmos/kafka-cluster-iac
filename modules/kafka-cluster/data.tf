
data "cloudinit_config" "foobar" {

  gzip          = false
  base64_encode = false
  for_each      = local.brokers

  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript"
    content      = file("${path.module}/scripts/init.sh")
  }

  part {
    filename     = "install-kafka.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/install-kafka.sh",
      {
        kafka_home = var.kafka_home
        log_dirs   = var.log_dirs
      }
    )
  }
  part {
    filename     = "setup-kafka-storage.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/format-kafka-storage.sh",
      {
        kafka_home                       = var.kafka_home
        initial_controllers              = local.initial_controllers
        kafka_server_properties_filename = local.kafka_server_properties_filename
        cluster_id                       = random_uuid.kafka_cluster_id.id
      }
    )
  }

  part {
    filename     = "setup-prometheus.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/setup-prometheus.sh",
      {
        prometheus_properties_filename = local.prometheus_properties_filename
        prometheus_properties_content  = file("${path.module}/prometheus/kafka_config.yml")
      }
    )
  }

  part {
    filename     = "setup-kafka-redis-connect.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/setup-kafka-redis-connect.sh",
      {
        redis_sink_properties_filename = local.redis_sink_connect_filename
        redis_sink_properties_content  = templatefile("${path.module}/properties/redis-sink.properties.tfpl", merge(var.redis_sink, { topics = var.topics }))
        connector_properties_filename  = local.connector_properties_filename
        connector_properties_content   = templatefile("${path.module}/properties/redis-sink.properties.tfpl", merge(var.redis_sink, { topics = var.topics }))
      }
    )
  }
  part { # FIXME Verificar setup-kafka-redis-connect.sh
    filename     = "setup-kafka-redis-connect.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/setup-kafka-redis-connect.sh",
      {
        kafka_home                    = var.kafka_home
        bootstrap_servers             = join(",", local.bootstrap_servers)
        topics                        = var.topics
        broker_name                   = each.value
        prometheus_properties_path    = local.prometheus_properties_filename
        redis_sink_properties_content = templatefile("${path.module}/properties/redis-sink.properties.tfpl", merge(var.redis_sink, { topics = var.topics }))
        connector_properties_path     = local.connector_properties_filename
        connector_properties_content  = templatefile("${path.module}/properties/redis-sink.properties.tfpl", { bootstrap_servers = join(",", local.bootstrap_servers), group_id = var.conect.group_id })
      }
    )
  }


}
