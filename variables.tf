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
  default = "us-central1-c"
}
variable "cluster_num" {
  default = 3
  type    = number
}