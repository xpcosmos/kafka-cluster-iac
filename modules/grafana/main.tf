locals {
  properties_files =[
    for f in fileset("${path.module}/properties", "**/**") :
    {
      filename = f
      content = file("${path.module}/properties/${f}")
    }
  ]
}

locals {
  script = templatefile("${path.module}/scripts/grafana-install.sh.tmpl",
    {
      files = local.properties_files
    }
  )
}
