# BIG-IP Management Public IP Addresses
output "mgmtPublicIP" {
  description = "List of BIG-IP public IP addresses for the management interfaces"
  value       = concat(aws_instance.f5_bigip.*.public_ip)[0]
}

# BIG-IP Management Public DNS
output "mgmtPublicDNS" {
  description = "List of BIG-IP public DNS records for the management interfaces"
  value       = concat(aws_instance.f5_bigip.*.public_dns)[0]
}

# BIG-IP Management Port
output "mgmtPort" {
  description = "HTTPS Port used for the BIG-IP management interface"
  value       = local.total_nics > 1 ? "443" : "8443"
}

output "f5_username" {
  value = (var.custom_user_data == null) ? var.f5_username : "Username as provided in custom runtime-init"
}

output "bigip_password" {
  description = "Password for bigip user ( if dynamic_password is choosen it will be random generated password or if aws_secretmanager_auth is choosen it will be aws secretmanager secret_id )"
  value       = (var.custom_user_data == null) ? ((var.f5_password == "") ? (var.aws_secretmanager_auth ? var.aws_secretmanager_secret_id : random_string.dynamic_password.result) : var.f5_password) : "Password as provided in custom runtime-init"
}

output "private_addresses" {
  description = "List of BIG-IP private addresses"
  value = {
    mgmt_private = {
      private_ip  = length(compact(local.mgmt_public_private_ip_primary)) > 0 ? aws_network_interface.mgmt.*.private_ip : aws_network_interface.mgmt1.*.private_ip
      private_ips = length(compact(local.mgmt_public_private_ip_primary)) > 0 ? aws_network_interface.mgmt.*.private_ips : aws_network_interface.mgmt1.*.private_ips
    }
    public_private = {
      private_ip  = length(concat(try(aws_network_interface.public.*.private_ip, []))) > 0 ? aws_network_interface.public.*.private_ip : aws_network_interface.public1.*.private_ip
      private_ips = length(compact(local.external_public_private_ip_primary)) > 0 ? aws_network_interface.public.*.private_ips : aws_network_interface.public1.*.private_ips
    }
    external_private = {
      private_ip  = length(compact(local.external_private_ip_primary)) > 0 ? aws_network_interface.external_private.*.private_ip : aws_network_interface.external_private1.*.private_ip
      private_ips = length(compact(local.external_private_ip_primary)) > 0 ? aws_network_interface.external_private.*.private_ips : aws_network_interface.external_private1.*.private_ips
    }
    internal_private = {
      private_ip  = length(compact(local.internal_private_ip_primary)) > 0 ? aws_network_interface.private.*.private_ip : aws_network_interface.private1.*.private_ip
      private_ips = length(compact(local.internal_private_ip_primary)) > 0 ? aws_network_interface.private.*.private_ips : aws_network_interface.private1.*.private_ips
    }
  }
}

output "public_addresses" {
  description = "List of BIG-IP public addresses"
  value = {
    external_primary_public   = concat(try(aws_eip.ext-pub.*.public_ip, []))
    external_secondary_public = concat(try(aws_eip.vip.*.public_ip, []))
  }
}

output "onboard_do" {
  value = local.total_nics > 1 ? (local.total_nics == 2 ? local.clustermemberDO2 : local.clustermemberDO3) : local.clustermemberDO1
}

output "bigip_instance_ids" {
  value = concat(aws_instance.f5_bigip.*.id)[0]
}