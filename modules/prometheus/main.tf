locals {
  static_configs = templatefile(
    "${path.module}/properties/prometheus.yml.tftpl",
    {
      job_name        = "kafka_cluster",
      scrape_interval = "5s",
      targets         = var.brokers
      labels          = {
        env = "dev"
        }
    }

  )
}

locals {
  script = templatefile("${path.module}/scripts/prometheus-install.sh",
    { content : local.static_configs }
  )
}
