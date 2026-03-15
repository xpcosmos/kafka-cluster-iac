
locals {
  files = [
    for f in fileset("${path.module}/app", "**") :
    {
      name    = f
      content = file("${path.module}/app/${f}")
    }
  ]
}

locals {
  script = templatefile(
    "${path.module}/scripts/producer.sh.tftpl",
    {
      files = local.files,
      workdir = var.workdir,
      bootstrap_servers = var.bootstrap_servers
      service = templatefile("${path.module}/services/producer.service",
      {
        workdir = var.workdir,
      }
      )
    }
  )
}
