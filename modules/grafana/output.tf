output "script" {
  value = local.script
}

output "type" {
  value = var.connection.type
}
output "user" {
  value = var.connection.user
}
output "private_key" {
  value = file(var.connection.private_key)
  sensitive = true
}
output "public_key" {
  value = file(var.connection.public_key)
  sensitive = true
}
output "dashboard_dir" {
  value = var.dashboard_dir
  sensitive = true
}

output "properties_files" {
  value = local.properties_files
}