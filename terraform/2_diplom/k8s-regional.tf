resource "yandex_kubernetes_cluster" "k8s-regional" {
  name                    = "k8s-regional"
  network_id              = yandex_vpc_network.ntlg-net.id
  release_channel         = "RAPID"
  network_policy_provider = "CALICO"

  labels = {
    app = "diplom"
  }

  master {
    version   = "1.22"
    public_ip = true


    regional {
      region = "ru-central1"
      location {
        zone      = yandex_vpc_subnet.public1a.zone
        subnet_id = yandex_vpc_subnet.public1a.id
      }
      location {
        zone      = yandex_vpc_subnet.public1b.zone
        subnet_id = yandex_vpc_subnet.public1b.id
      }
      location {
        zone      = yandex_vpc_subnet.public1c.zone
        subnet_id = yandex_vpc_subnet.public1c.id
      }
    }

    security_group_ids = [
      yandex_vpc_security_group.k8s-main-sg.id,
      yandex_vpc_security_group.k8s-master-whitelist.id
    ]

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "01:00"
        duration   = "3h"
      }
    }

    # master_logging {
    #   enabled = true
    #   log_group_id = "${yandex_logging_group.log_group_resoruce_name.id}"
    #   kube_apiserver_enabled = true
    #   cluster_autoscaler_enabled = true
    #   events_enabled = true
    # }
  }
  service_account_id      = yandex_iam_service_account.k8s-account.id
  node_service_account_id = yandex_iam_service_account.k8s-account.id

  depends_on = [
    yandex_resourcemanager_folder_iam_binding.k8s-clusters-agent,
    yandex_resourcemanager_folder_iam_binding.vpc-public-admin,
    yandex_resourcemanager_folder_iam_binding.images-puller,
    # FIXME - а надо ли оно тут???
    #yandex_resourcemanager_folder_iam_binding.load-balancer-admin
  ]

  kms_provider {
    key_id = yandex_kms_symmetric_key.key-g.id
  }
}


