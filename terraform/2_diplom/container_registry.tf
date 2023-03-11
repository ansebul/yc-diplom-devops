resource "yandex_container_registry" "container-registry" {
  name      = "container-registry"
  folder_id = var.yandex_folder_id
}
