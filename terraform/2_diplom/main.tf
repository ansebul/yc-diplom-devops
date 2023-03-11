terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoint = "storage.yandexcloud.net"
    bucket   = "tf-state-bas-2023"
    region   = "ru-central1"
    key      = "terraform/terraform.tfstate"
    #access_key   = via environment variable!
    #secret_key   = via environment variable!

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  folder_id = var.yandex_folder_id
  zone      = "ru-central1-a"
}
