resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static access key for object storage"
}

resource "yandex_storage_bucket" "terraform-state" {
  bucket        = "tf-state-bas-2023"
  access_key    = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key    = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  force_destroy = true
  anonymous_access_flags {
    read = false
    list = false
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-bde.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
