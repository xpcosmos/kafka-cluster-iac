variable "workdir" {
  default = "app"
  type = string
}

variable "bootstrap_servers" {
  type = set(string)
}