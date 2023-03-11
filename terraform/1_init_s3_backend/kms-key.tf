resource "yandex_kms_symmetric_key" "key-bde" {
  name              = "key-buckets-data-encode"
  description       = "Only for buckets content encode"
  default_algorithm = "AES_128"
  rotation_period   = "1464h" // equal to 2 months
}
