resource "yandex_iam_service_account" "k8s-account" {
  name        = "k8s-account"
  description = "K8S service account"
}

resource "yandex_resourcemanager_folder_iam_binding" "vpc-public-admin" {
  # Сервисному аккаунту назначается роль "vpc.publicAdmin".
  # https://cloud.yandex.ru/docs/iam/concepts/access-control/roles#vpc-public-admin
  folder_id = var.yandex_folder_id
  role      = "vpc.publicAdmin"
  members = [
    "serviceAccount:${yandex_iam_service_account.k8s-account.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s-clusters-agent" {
  # Сервисному аккаунту назначается роль "k8s.clusters.agent".
  folder_id = var.yandex_folder_id
  role      = "k8s.clusters.agent"
  members = [
    "serviceAccount:${yandex_iam_service_account.k8s-account.id}"
  ]
}

resource "yandex_kms_symmetric_key_iam_binding" "viewer" {
  symmetric_key_id = yandex_kms_symmetric_key.key-g.id
  role             = "viewer"
  members = [
    "serviceAccount:${yandex_iam_service_account.k8s-account.id}",
  ]
}

resource "yandex_resourcemanager_folder_iam_member" "encryptor" {
  # Для шифровки/дешифровки данных в кластере Кубера
  folder_id = var.yandex_folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-account.id}"
}

resource "yandex_resourcemanager_folder_iam_binding" "load-balancer-admin" {
  # Для создания балансировщика через манифест.
  folder_id = var.yandex_folder_id
  role      = "load-balancer.admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.k8s-account.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "images-puller" {
  # Для работы с Container Registry назначается роль "container-registry.images.puller".
  # https://cloud.yandex.ru/docs/iam/concepts/access-control/roles#cr-images-puller
  folder_id = var.yandex_folder_id
  role      = "container-registry.images.puller"
  members = [
    "serviceAccount:${yandex_iam_service_account.k8s-account.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "images-pusher" {
  # Для работы с Container Registry назначается роль "container-registry.images.pusher".
  # https://cloud.yandex.ru/docs/iam/concepts/access-control/roles#cr-images-pusher
  folder_id = var.yandex_folder_id
  role      = "container-registry.images.pusher"
  members = [
    "serviceAccount:${yandex_iam_service_account.k8s-account.id}"
  ]
}
