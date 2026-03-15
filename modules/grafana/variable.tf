variable "connection" {

  type = object({
    type = string
    user = string
    private_key = string
    public_key = string
  })
  # validation {
  #   condition = length(regex("^[/[a-zA-Z0-9-_.]+$", var.connection.private_key)) == 1
  #   error_message = "esperava um caminho para uma chave privada"
  # }
  # validation {
  #   condition = length(regex("^[/[a-zA-Z0-9-_.]+.pub$", var.connection.public_key)) == 1
  #   error_message = "esperava um caminho para a chave publica"
  # }
  # validation {
  #   condition = var.connection.public_key != "ssh"
  #   error_message = "esperava `ssh`"
  # }
}

variable "dashboard_dir" {
  type = string
  # validation {
  #   condition = length(regex("^[/[a-zA-Z0-9-_.]+(?<!/)$", var.dashboard_dir)) == 1
  #   error_message = "esperava um caminho para um diretorio"
  # }
}