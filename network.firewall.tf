
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
resource "google_compute_firewall" "deny-incoming" {
  name        = "deny-incoming"
  network     = google_compute_network.kafka_network.id
  source_tags = ["deny-incoming"]
  direction   = "INGRESS"
  priority    = 100

  deny {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  deny {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  deny {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

################################## Conexao SSH ######################################

resource "google_compute_firewall" "kafka-ssh" {
  name        = "kafka-shh"
  network     = google_compute_network.kafka_network.id
  source_tags = ["ssh","allow-ssh"]
  priority    = 0

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_firewall" "allow-in-prometheus" {
  name        = "allow-in-prometheus"
  network     = google_compute_network.kafka_network.id
  source_tags = ["allow-in-prometheus"]
  priority    = 50

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }
  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }
  source_ranges = ["0.0.0.0/0"]
}