# Get the hash of all relevant files that should trigger a rebuild
data "external" "source_hash" {
  program = ["bash", "-c", <<EOF
    {
      if [ -f "${var.package_file}" ]; then
        echo "{\"hash\": \"$(sha1sum ${var.package_file} | cut -d ' ' -f1)\"}"
      else
        echo "{\"hash\": \"no-package-file\"}"
      fi
    }
  EOF
  ]
}

locals {
  dist  = abspath("${path.module}/dist/${data.external.source_hash.result.hash}")
  archive = "${local.dist}.zip"
}

resource "null_resource" "build" {
  triggers = {
    # Only rebuild when the package file changes
    package_file_hash = data.external.source_hash.result.hash
  }

  provisioner "local-exec" {
    command = "${path.module}/build.sh"
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
    null_resource.build
  ]
}
