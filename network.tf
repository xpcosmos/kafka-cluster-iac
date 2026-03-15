
############################## Definicao de Rede ##################################

resource "google_compute_network" "kafka_network" {
  name = "kafka-network"
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
