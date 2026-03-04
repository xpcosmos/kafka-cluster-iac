
########################### Conexao Interna entre VM ################################

resource "google_compute_firewall" "kafka-broker" {
  name        = "kafka-broker"
  network     = google_compute_network.kafka_network.id
  source_tags = ["kafka"]
  priority    = 0

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.0.0.0/9"]
}

################################## Conexao SSH ######################################

resource "google_compute_firewall" "kafka-ssh" {
  name        = "kafka-shh"
  network     = google_compute_network.kafka_network.id
  source_tags = ["ssh"]
  priority    = 0

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}