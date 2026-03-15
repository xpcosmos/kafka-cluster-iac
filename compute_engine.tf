
module "kafka_producer_app" {
  source            = "./modules/kafka-producer"
  bootstrap_servers = module.kafka_cluster_server.bootstrap_servers
}

module "redis_server" {
  source            = "./modules/redis"
}

module "grafana" {
  source = "./modules/grafana"
  dashboard_dir = "${path.module}/grafana/dashboards"
  connection = {
    type = "ssh"
    user = "mikeiasoliveira"
    private_key = "${path.module}/.keys/keys"
    public_key = "${path.module}/.keys/keys.pub"
  }
}

module "prometheus" {
  source = "./modules/prometheus"
  brokers = module.kafka_cluster_server.brokers
  connect_cluster_id = module.kafka_cluster_server.connect_group_id
}

module "kafka_cluster_server" {
  source     = "./modules/kafka-cluster"
  controller = { port = 9093 }
  broker     = { port = 9092 }
  connect = {
    group_id = "kafka_connect"
  }
  topics = "teste"
  redis_sink = {
    host = "redis"
    port = 6379
  }
  cluster_size = 3
}


############################### Configuracao de VMs ###############################

resource "google_compute_instance" "kafka" {

  for_each     = module.kafka_cluster_server.cluster_instance
  name         = each.key
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
  metadata_startup_script = each.value
  depends_on              = [google_compute_instance.redis]
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

  metadata_startup_script = module.kafka_producer_app.script

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
  metadata_startup_script = module.redis_server.script
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
  metadata_startup_script = module.prometheus.script
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
    ssh-keys = "${module.grafana.user}:${module.grafana.public_key}"

  }



  provisioner "remote-exec" {
    inline = ["echo 'SSH is up!'"]
  }
  provisioner "file" {
    source      = module.grafana.dashboard_dir
    destination = "/tmp/dashboards"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /var/lib/grafana",
      "sudo mv /tmp/dashboards /var/lib/grafana/dashboards",
    ]
  }
  tags = ["kafka", "default-allow-internal", "https-server", "http-server", "allow-in-prometheus"]
  metadata_startup_script = module.grafana.script
  connection {
    type        = module.grafana.type
    user        = module.grafana.user
    private_key = module.grafana.private_key
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
