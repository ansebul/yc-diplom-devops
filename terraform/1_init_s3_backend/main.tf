terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

}

provider "yandex" {
  folder_id = var.yandex_folder_id
  zone      = "ru-central1-a"
}
