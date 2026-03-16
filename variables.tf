variable "project_id" {
  type    = string
  default = "projeto-kafka-pos"
}
variable "project_region" {
  type    = string
  default = "us-central1"
}
variable "project_zone" {
  type    = string
  default = "us-central1-b"
}
variable "num_partitions" {
  default = 3
  type    = number
}
variable "user" {
  default = "mikeiasoliveira"
  type    = string
}
variable "private_key" {
  default = "${path.module}/.keys/keys"
  type    = string
}
variable "public_key" {
  default = "${path.module}/.keys/keys.pub"
  type    = string
}
variable "controller" {
  default = { port = 9093 }
}
variable "broker" {
  default = { port = 9092 }
}
variable "connect" {
  default = {
    group_id = "kafka_connect"
  }
}
variable "topics" {
  default = "teste"
}
variable "redis_sink" {
  default = {
    host = "redis"
    port = 6379
  }
}
variable "cluster_size" {
  default = 3
}
