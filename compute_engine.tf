
# Definicao de ID de cluster
resource "random_uuid" "kafka_cluster_id" {}

# Definicao de UUID para diretorios
resource "random_bytes" "uuid_binary" {
  count  = var.cluster_num
  length = 16
}

############################# Definicao de Variaveis ##############################

locals {
  # Define dinamicamente hostnames para configuracao do
  # quorum bootstrap server.
  controller_quorum_bootstrap_servers = join(
    ",",
    [
      for i in range(var.cluster_num) :
      "kafka-broker-${i}:9093"
    ]
  )
  bootstrap_servers = join(
    ",",
    [
      for i in range(var.cluster_num) :
      "kafka-broker-${i}:9092"
    ]
  )

  # Define dinamicamente parametro de inicializacao de cluster
  # e formatacao para o nos.
  # Essse valor e compartilhado com o arquivo `startup.sh`, com
  # intuito de fornecer antecidamente os IDs de Cluster e diretorio
  # e compartilhar entre os nos
  initial_controllers = join(
    ",",
    [
      for i in range(var.cluster_num) :
      "${i}@kafka-broker-${i}:9093:${
        replace(
          replace(
            replace(random_bytes.uuid_binary[i].base64, "+", "-"),
            "/", "_"
          ),
          "=", ""
        )
      }"
  ])
}

############################### Configuracao de VMs ###############################

resource "google_compute_instance" "kafka" {

  # Quantidade de nos a serem criados
  count = var.cluster_num
  # Esquema de nomeacao de nos [kafka-broker-<indice>]
  name         = "kafka-broker-${count.index}"
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
  }

  # Tags para permitir configuracao de acesso interno entre VMs
  tags = ["kafka", "default-allow-internal","deny-incoming"]

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
      redis_sink_properties_file          = file("${path.module}/properties/redis-sink.properties")
      prometheus_kafka_config_file        = file("${path.module}/properties/kafka_config.yml")
    }

  )
  depends_on = [google_compute_instance.redis]
}

resource "google_compute_instance" "kafka-producer" {
  name         = "kafka-producer"
  machine_type = "e2-small"
  network_interface {
    network = google_compute_network.kafka_network.id
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }
  tags = ["kafka", "default-allow-internal","deny-incoming"]

  metadata_startup_script = templatefile("${path.module}/templates/produtor.sh.tmpl",
    {
      workdir                            = "app",
      bootstrap_servers                  = local.bootstrap_servers
      delivery_tracking_simulator_script = file("${path.module}/scripts/delivery_tracking_simulator.py")
      producer_script                    = file("${path.module}/scripts/producer.py")
      requirements_file                  = file("${path.module}/scripts/requirements.txt")
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
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }
  tags                    = ["kafka", "default-allow-internal","deny-incoming"]
  metadata_startup_script = file("redis-install.sh")
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
  ${file("prometheus-install.sh")}
EOT
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
