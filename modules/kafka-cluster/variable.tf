variable "cluster_size" {
  default = 3
  type    = number
}
variable "partitions_num" {
  default = 3
  type    = number
}

variable "topics" {
  type = string
}

variable "redis_sink" {
  type    = object({
    host = string
    port = number
  })
}

variable "connect" {
  type    = object({
    group_id = string
  })
}

variable "controller" {
  default = object({
    port = 9093
  })
  type = object({
    port = number
  })
}

variable "broker" {
  default = object({
    port = 9092
  })
  type = object({
    port = number
  })
}
variable "kafka_home" {
  default = "/opt/kafka"
  type    = string
}
variable "log_dirs" {
  default = "/var/kafka"
  type    = string
}
