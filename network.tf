
############################## Definicao de Rede ##################################

resource "google_compute_network" "kafka_network" {
  name = "kafka-network"
}