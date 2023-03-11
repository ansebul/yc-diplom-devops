resource "yandex_kms_symmetric_key" "key-g" {
  name              = "general-key"
  description       = "For data encryption"
  default_algorithm = "AES_128"
  rotation_period   = "1464h" // equal to 2 months
}
