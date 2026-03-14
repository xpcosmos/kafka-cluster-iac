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

output "metadata_startup_script" {
  value = [
   
    templatefile("${path.module}/properties/server.properties",
      {

        node_id     = i,
        broker_name = broker,

        quorum_bootstrap_servers = join(",", local.quorum_bootstrap_servers)

        log_dirs       = var.log_dirs
        partitions_num = var.partitions_num
        controler      = var.controller
        broker         = var.broker
    })
  ]
}
