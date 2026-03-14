


module "kafka_cluster_server" {
  source = "./modules/kafka-cluster"
  controller = {port = 9093}
  broker = {port = 9092}
}


############################### Configuracao de VMs ###############################

resource "google_compute_instance" "kafka" {

  for_each = module.kafka_cluster_server.bootstrap_servers
  count = var.cluster_num
  name         = each.value
  machine_type = "e2-medium" # 2 vCPUs @ 4 GB RAM

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }
  network_interface {
    network = google_compute_network.kafka_network.id
    access_config {}
  }

  # Tags para permitir configuracao de acesso interno entre VMs
  tags = ["kafka", "default-allow-internal", "deny-incoming"]

  # Definicao de script de Inicializacao. Esse script ira ser rodado
  # no momento em que VM iniciar. Algumas variaveis sao definidas aqui e compartilhadas
  # com o script `startup.sh`. A variavel `CONTROLLER_QUORUM_BOOTSTRAP_SERVERS` e definida
  # aqui apenas por uma questao de conveniencia
  metadata_startup_script = templatefile(
    "${path.module}/templates/kafka-startup.sh.tmpl",
    {
      kafka_cluster_id                    = random_uuid.kafka_cluster_id.id
      kafka_home                          = "/opt/kafka"
      instance_number                     = count.index
      log_dirs                            = "/var/kafka"
      controller_quorum_bootstrap_servers = local.controller_quorum_bootstrap_servers
      initial_controllers                 = local.initial_controllers
      partitions_num                      = var.num_partitions
      bootstrap_servers                   = local.bootstrap_servers
      redis_sink_properties_file          = file("${path.module}/properties/redis-sink.properties.tmpl")
      connector_properties_file = templatefile("${path.module}/properties/connect.properties.tmpl",
        {
          bootstrap_servers = local.bootstrap_servers,
          group_id          = "kafka-connect"
        }
      )
      prometheus_kafka_config_file = file("${path.module}/prometheus/kafka_config.yml")
    }

  )
  depends_on = [google_compute_instance.redis]
}

resource "google_compute_instance" "kafka-producer" {
  name         = "kafka-producer"
  machine_type = "e2-small"
  network_interface {
    network = google_compute_network.kafka_network.id
    access_config {}
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }
  tags = ["kafka", "default-allow-internal", "deny-incoming"]

  metadata_startup_script = templatefile("${path.module}/templates/produtor.sh.tmpl",
    {
      workdir                            = "app",
      bootstrap_servers                  = local.bootstrap_servers
      delivery_tracking_simulator_script = file("${path.module}/producer/delivery_tracking_simulator.py")
      producer_script                    = file("${path.module}/producer/producer.py")
      requirements_file                  = file("${path.module}/producer/requirements.txt")
    }
  )

  depends_on = [
    google_compute_instance.kafka
  ]
}

resource "google_compute_instance" "redis" {
  name         = "redis"
  machine_type = "e2-medium"
  network_interface {
    network = google_compute_network.kafka_network.id
    access_config {}
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }
  tags                    = ["kafka", "default-allow-internal", "deny-incoming"]
  metadata_startup_script = file("${path.module}/scripts/redis-install.sh")
}

resource "google_compute_instance" "prometheus" {
  name         = "prometheus"
  machine_type = "e2-medium"
  network_interface {
    network = google_compute_network.kafka_network.id
    access_config {
      nat_ip = google_compute_address.external_ip_address.address
    }

  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }
  tags                    = ["kafka", "default-allow-internal", "https-server", "http-server", "allow-in-prometheus"]
  metadata_startup_script = <<EOT
  ${file("${path.module}/scripts/prometheus-install.sh")}
EOT
}

resource "google_compute_instance" "grafana" {
  name         = "grafana"
  machine_type = "e2-medium"
  network_interface {
    network = google_compute_network.kafka_network.id
    access_config {
      nat_ip = google_compute_address.external_ip_address_grafana.address
    }
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }
  metadata = {
    ssh-keys = "mikeiasoliveira:${file("${path.module}/.keys/keys.pub")}"
  }
  provisioner "remote-exec" {
    inline = ["echo 'SSH is up!'"]
  }
  provisioner "file" {
    source =   "${path.module}/grafana/dashboards"
    destination = "/tmp/dashboards"
  }
  provisioner "remote-exec" {
    inline = [
        "sudo mkdir -p /var/lib/grafana",
        "sudo mv /tmp/dashboards /var/lib/grafana/dashboards",
        "sudo chown -R grafana:grafana /var/lib/grafana/dashboards"
    ]
}
  tags = ["kafka", "default-allow-internal", "https-server", "http-server", "allow-in-prometheus"]
  metadata_startup_script = templatefile("${path.module}/scripts/grafana-install.sh.tmpl",
    {
      dashboard_yml : file("${path.module}/grafana/provisioning/dashboards/dashboard.yml")
      datasources_yml : file("${path.module}/grafana/provisioning/datasources/datasource.yml")
    }
  )
    connection {
      type        = "ssh"
      user        = "mikeiasoliveira"
      private_key = file("${path.module}/.keys/keys")
      host        = self.network_interface[0].access_config[0].nat_ip
    }

}

resource "google_compute_address" "external_ip_address" {
  name         = "external-ip-static"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

output "instance_external_ip" {
  value       = google_compute_address.external_ip_address.address
  description = "The static external IP address of the VM instance"
}

resource "google_compute_address" "external_ip_address_grafana" {
  name         = "external-ip-static-grafana"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}
output "external_ip_address_grafana" {
  value       = google_compute_address.external_ip_address_grafana.address
  description = "The static external IP address of the VM instance"
}
