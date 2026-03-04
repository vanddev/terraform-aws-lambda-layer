# Generate a hash of the package file to trigger rebuilds
locals {
  # Create a hash based on file content or a default value
  package_file_hash = var.package_file != null ? filemd5(var.package_file) : "no-package-file"
  dist_hash         = substr(local.package_file_hash, 0, 40)
  dist              = abspath("${path.module}/dist/${local.dist_hash}")
  archive           = "${local.dist}.zip"
}

# Build the Lambda layer using terraform_data and local-exec
resource "terraform_data" "build" {
  triggers_replace = [local.package_file_hash]

  provisioner "local-exec" {
    command = "bash ${path.module}/build.sh"
    environment = {
      DIST_DIR      = local.dist
      SOURCE_DIR    = var.source_dir
      SOURCE_TYPE   = var.source_type
      PACKAGE_FILE  = var.package_file
      RSYNC_PATTERN = join(" ", var.rsync_pattern)
    }
  }
}

data "archive_file" "layer" {
  type        = "zip"
  source_dir  = local.dist
  output_path = local.archive

  depends_on = [
    terraform_data.build
  ]
}
