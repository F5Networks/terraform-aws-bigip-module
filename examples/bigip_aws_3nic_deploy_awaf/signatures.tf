variable "signatures" {
  type = map(object({
    signature_id    = number
    enabled         = bool
    perform_staging = bool
    description     = string
  }))
}

data "bigip_waf_signatures" "map" {
  for_each        = var.signatures
  signature_id    = each.value["signature_id"]
  description     = each.value["description"]
  enabled         = each.value["enabled"]
  perform_staging = each.value["perform_staging"]
  depends_on      = [module.bigip]
}