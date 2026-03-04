
############################## Definicao de Rede ##################################

resource "google_compute_network" "kafka_network" {
  name = "kafka-network"
}

############################## Definicao de Router ################################

resource "google_compute_router" "kafka_router" {
  name    = "kafka-router"
  network = google_compute_network.kafka_network.id
}

############################### Definicao de NAT #################################

resource "google_compute_router_nat" "kafka_nat" {
  name                               = "kafka-nat"
  router                             = google_compute_router.kafka_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


