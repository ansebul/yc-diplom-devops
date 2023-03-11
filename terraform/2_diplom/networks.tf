#
# Зона ru-central1-c с ограничениями! Выводится из эксплуатации!
#

# Public subnet
#
resource "yandex_vpc_subnet" "public1a" {
  name           = "public-subnet-1a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.ntlg-net.id
  v4_cidr_blocks = ["10.1.0.0/16"]
}
resource "yandex_vpc_subnet" "public1b" {
  name           = "public-subnet-1b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.ntlg-net.id
  v4_cidr_blocks = ["10.2.0.0/16"]
}
resource "yandex_vpc_subnet" "public1c" {
  name           = "public-subnet-1c"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.ntlg-net.id
  v4_cidr_blocks = ["10.3.0.0/16"]
}


# FIXME - удалить, если не найду применения

# Private subnets
#
# resource "yandex_vpc_subnet" "private1a" {
#   name           = "private-subnet-1a"
#   zone           = "ru-central1-a"
#   network_id     = yandex_vpc_network.ntlg-net.id
#   v4_cidr_blocks = ["10.4.0.0/16"]
# }
# resource "yandex_vpc_subnet" "private1b" {
#   name           = "private-subnet-1b"
#   zone           = "ru-central1-b"
#   network_id     = yandex_vpc_network.ntlg-net.id
#   v4_cidr_blocks = ["10.5.0.0/16"]
# }
# resource "yandex_vpc_subnet" "private1c" {
#   name           = "private-subnet-1c"
#   zone           = "ru-central1-c"
#   network_id     = yandex_vpc_network.ntlg-net.id
#   v4_cidr_blocks = ["10.6.0.0/16"]
# }
