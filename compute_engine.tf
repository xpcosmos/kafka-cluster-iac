
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
  tags = ["kafka", "default-allow-internal"]

  # Definicao de script de Inicializacao. Esse script ira ser rodado
  # no momento em que VM iniciar. Algumas variaveis sao definidas aqui e compartilhadas
  # com o script `startup.sh`. A variavel `CONTROLLER_QUORUM_BOOTSTRAP_SERVERS` e definida
  # aqui apenas por uma questao de conveniencia
  metadata_startup_script = <<EOT
    ############################# Configuracao de VMs #############################

    export KAFKA_CLUSTER_ID=${random_uuid.kafka_cluster_id.id}
    export KAFKA_INSTANCE_NUM=${count.index}
    export CONTROLLER_QUORUM_BOOTSTRAP_SERVERS=${local.controller_quorum_bootstrap_servers}
    export INITIAL_CONTROLLERS=${local.initial_controllers}
    export KAFKA_NUM_PARTITIONS=${var.num_partitions}

    ############################### Script Startup ################################

    ${file("startup.sh")}

  EOT
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
  tags = ["kafka", "default-allow-internal"]

  metadata_startup_script = <<EOT
  sudo apt update
  sudo apt update
  sudo apt install python3-pip -y
  sudo mkdir -p app
  export BOOTSTRAP_SERVERS=${local.initial_controllers}

cat << 'DELIVERY_TRACK' > app/delivery_tracking_simulator.py
${file("${path.module}/scripts/delivery_tracking_simulator.py")}
DELIVERY_TRACK

cat << 'PRODUCER_PY_FILE' > app/producer.py
${file("${path.module}/scripts/producer.py")}
PRODUCER_PY_FILE

cat << 'REQ' > app/requirements.txt
${file("${path.module}/scripts/requirements.txt")}
REQ

  sudo pip install -r app/requirements.txt
  python3 app/delivery_tracking_simulator.py
  EOT

  depends_on = [
    google_compute_instance.kafka
  ]
}
