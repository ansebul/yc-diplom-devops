# Так как нам надо обеспечить отказоустойчивость,
# то ноды должны создаваться в 3-х зонах. 
#
# Однако одну kubernetes_node_group можно расположить
# только в одной зоне, поэтому требование о размещении нод
# в 3-х разных подсетях реализуем так:
# по 1-й группе из 1 машины с автомасштабированием до 2-х
# и раскидываем их в 3-х зонах.

resource "yandex_kubernetes_node_group" "k8s-group-1a" {
  cluster_id = yandex_kubernetes_cluster.k8s-regional.id
  name       = "k8s-group-1a"

  labels = {
    app = "diplom"
  }

  instance_template {
    name = "node-1a-{instance.short_id}"

    labels = {
      app = "diplom"
    }


    # https://cloud.yandex.ru/docs/compute/concepts/vm-platforms
    platform_id = "standard-v1"

    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 30
    }

    container_runtime {
      type = "containerd"
    }

    network_interface {
      nat        = true
      subnet_ids = ["${yandex_vpc_subnet.public1a.id}"]
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
    # Вот почему не можем расположить группу в нескольких зонах:
    # Validation error: allocation_policy.locations: auto scale node groups can have only one location
    # location {
    #   zone = "ru-central1-b"
    # }
    # location {
    #   zone = "ru-central1-c"
    # }
  }

  scale_policy {
    auto_scale {
      min     = 1
      max     = 2
      initial = 1
    }
  }
}


resource "yandex_kubernetes_node_group" "k8s-group-1b" {
  cluster_id = yandex_kubernetes_cluster.k8s-regional.id
  name       = "k8s-group-1b"

  labels = {
    app = "diplom"
  }

  instance_template {
    name        = "node-1b-{instance.short_id}"
    platform_id = "standard-v1"

    labels = {
      app = "diplom"
    }

    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 30
    }

    container_runtime {
      type = "containerd"
    }

    network_interface {
      nat        = true
      subnet_ids = ["${yandex_vpc_subnet.public1b.id}"]
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-b"
    }
  }

  scale_policy {
    auto_scale {
      min     = 1
      max     = 2
      initial = 1
    }
  }
}


resource "yandex_kubernetes_node_group" "k8s-group-1c" {
  cluster_id = yandex_kubernetes_cluster.k8s-regional.id
  name       = "k8s-group-1c"

  labels = {
    app = "diplom"
  }

  instance_template {
    name        = "node-1c-{instance.short_id}"
    platform_id = "standard-v1"

    labels = {
      app = "diplom"
    }

    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 30
    }

    container_runtime {
      type = "containerd"
    }

    network_interface {
      nat        = true
      subnet_ids = ["${yandex_vpc_subnet.public1c.id}"]
      security_group_ids = [
        yandex_vpc_security_group.k8s-main-sg.id,
        yandex_vpc_security_group.k8s-public-services.id,
        yandex_vpc_security_group.k8s-nodes-ssh-access.id
      ]
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-c"
    }
  }

  scale_policy {
    auto_scale {
      min     = 1
      max     = 2
      initial = 1
    }
  }
}
