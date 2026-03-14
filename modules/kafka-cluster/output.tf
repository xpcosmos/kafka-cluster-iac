output "quorum_bootstrap_servers" {
  value = local.quorum_bootstrap_servers
}
output "bootstrap_servers" {
  value = local.bootstrap_servers
}
output "initial_controllers" {
  value = local.initial_controllers
}
output "cluster_id" {
  value = random_uuid.kafka_cluster_id.id
}

output "cluster_instance" {
  value = data.cloudinit_config.metadata_startup_script
}
