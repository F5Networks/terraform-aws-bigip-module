locals {
  bigip_map = {
    "mgmt_subnet_ids"            = var.mgmt_subnet_ids
    "mgmt_securitygroup_ids"     = var.mgmt_securitygroup_ids
    "external_subnet_ids"        = var.external_subnet_ids
    "external_securitygroup_ids" = var.external_securitygroup_ids
    "internal_subnet_ids"        = var.internal_subnet_ids
    "internal_securitygroup_ids" = var.internal_securitygroup_ids
  }
  mgmt_public_subnet_id = [
    for subnet in local.bigip_map["mgmt_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == true
  ]
  mgmt_public_index = [
    for index, subnet in local.bigip_map["mgmt_subnet_ids"] :
    index
    if subnet["public_ip"] == true
  ]
  mgmt_public_security_id = [
    for i in local.mgmt_public_index : local.bigip_map["mgmt_securitygroup_ids"][i]
  ]
  mgmt_private_subnet_id = [
    for subnet in local.bigip_map["mgmt_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == false
  ]
  mgmt_private_index = [
    for index, subnet in local.bigip_map["mgmt_subnet_ids"] :
    index
    if subnet["public_ip"] == false
  ]
  mgmt_private_security_id = [
    for i in local.mgmt_private_index : local.bigip_map["mgmt_securitygroup_ids"][i]
  ]
  external_public_subnet_id = [
    for subnet in local.bigip_map["external_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == true
  ]
  external_public_index = [
    for index, subnet in local.bigip_map["external_subnet_ids"] :
    index
    if subnet["public_ip"] == true
  ]
  external_public_security_id = [
    for i in local.external_public_index : local.bigip_map["external_securitygroup_ids"][i]
  ]
  external_private_subnet_id = [
    for subnet in local.bigip_map["external_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == false
  ]
  external_private_index = [
    for index, subnet in local.bigip_map["external_subnet_ids"] :
    index
    if subnet["public_ip"] == false
  ]
  external_private_security_id = [
    for i in local.external_private_index : local.bigip_map["external_securitygroup_ids"][i]
  ]
  internal_public_subnet_id = [
    for subnet in local.bigip_map["internal_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == true
  ]
  internal_public_index = [
    for index, subnet in local.bigip_map["internal_subnet_ids"] :
    index
    if subnet["public_ip"] == true
  ]
  internal_public_security_id = [
    for i in local.internal_public_index : local.bigip_map["internal_securitygroup_ids"][i]
  ]
  internal_private_subnet_id = [
    for subnet in local.bigip_map["internal_subnet_ids"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == false
  ]
  internal_private_index = [
    for index, subnet in local.bigip_map["internal_subnet_ids"] :
    index
    if subnet["public_ip"] == false
  ]
  internal_private_security_id = [
    for i in local.internal_private_index : local.bigip_map["internal_securitygroup_ids"][i]
  ]
  internal_private_ip_primary = [
    for private in local.bigip_map["internal_subnet_ids"] :
    private["private_ip_primary"]
    if private["public_ip"] == false
  ]
  external_private_ip_primary = [
    for private in local.bigip_map["external_subnet_ids"] :
    private["private_ip_primary"]
    if private["public_ip"] == false
  ]
  external_private_ip_secondary = [
    for private in local.bigip_map["external_subnet_ids"] :
    private["private_ip_secondary"]
    if private["public_ip"] == false
  ]
  external_public_private_ip_primary = [
    for private in local.bigip_map["external_subnet_ids"] :
    private["private_ip_primary"]
    if private["public_ip"] == true
  ]
  external_public_private_ip_secondary = [
    for private in local.bigip_map["external_subnet_ids"] :
    private["private_ip_secondary"]
    if private["public_ip"] == true
  ]
  mgmt_private_ip_primary = [
    for private in local.bigip_map["mgmt_subnet_ids"] :
    private["private_ip_primary"]
    if private["public_ip"] == false
  ]
  mgmt_public_private_ip_primary = [
    for private in local.bigip_map["mgmt_subnet_ids"] :
    private["private_ip_primary"]
    if private["public_ip"] == true
  ]

  total_nics       = length(concat(local.mgmt_public_subnet_id, local.mgmt_private_subnet_id, local.external_public_subnet_id, local.external_private_subnet_id, local.internal_public_subnet_id, local.internal_private_subnet_id))
  vlan_list        = concat(local.external_public_subnet_id, local.external_private_subnet_id, local.internal_public_subnet_id, local.internal_private_subnet_id)
  selfip_list_temp = concat(aws_network_interface.public.*.private_ip, aws_network_interface.external_private.*.private_ip, aws_network_interface.private.*.private_ip, aws_network_interface.public1.*.private_ip, aws_network_interface.external_private1.*.private_ip, aws_network_interface.private1.*.private_ip)
  ext_interfaces   = concat(aws_network_interface.public.*.id, aws_network_interface.public1.*.id, aws_network_interface.external_private.*.id, aws_network_interface.external_private1.*.id)
  selfip_list      = flatten(local.selfip_list_temp)
  //bigip_nics       = concat(aws_network_interface.public.*.id, aws_network_interface.external_private.*.id,aws_network_interface.private.*.id)
  //bigip_nics_map   = concat(data.aws_network_interfaces.bigip_nic.*.private_ip)
  instance_prefix = format("%s-%s", var.prefix, random_id.module_id.hex)

  tags = merge(var.tags, {
    Prefix = format("%s", local.instance_prefix)
    }
  )
  f5_hostname = var.f5_hostname != "" ? var.f5_hostname : (
    length(aws_eip.mgmt) > 0 ? aws_eip.mgmt[0].public_dns : ""
  )

  clustermemberDO1 = local.total_nics == 1 ? templatefile("${path.module}/templates/onboard_do_1nic.tpl", {
    hostname      = local.f5_hostname
    name_servers  = join(",", formatlist("\"%s\"", ["169.254.169.253"]))
    search_domain = "f5.com"
    ntp_servers   = join(",", formatlist("\"%s\"", ["169.254.169.123"]))
  }) : ""

  clustermemberDO2 = local.total_nics == 2 ? templatefile("${path.module}/templates/onboard_do_2nic.tpl", {
    hostname      = local.f5_hostname
    name_servers  = join(",", formatlist("\"%s\"", ["169.254.169.253"]))
    search_domain = "f5.com"
    ntp_servers   = join(",", formatlist("\"%s\"", ["169.254.169.123"]))
    vlan-name     = element(split("/", local.vlan_list[0]), length(split("/", local.vlan_list[0])) - 1)
    self-ip       = local.selfip_list[0]
    gateway       = cidrhost(format("%s/24", local.selfip_list[0]), 1)
  }) : ""

  clustermemberDO3 = local.total_nics >= 3 ? templatefile("${path.module}/templates/onboard_do_3nic.tpl", {
    hostname      = local.f5_hostname
    name_servers  = join(",", formatlist("\"%s\"", ["169.254.169.253"]))
    search_domain = "f5.com"
    ntp_servers   = join(",", formatlist("\"%s\"", ["169.254.169.123"]))
    vlan-name1    = element(split("/", local.vlan_list[0]), length(split("/", local.vlan_list[0])) - 1)
    self-ip1      = local.selfip_list[0]
    gateway       = cidrhost(format("%s/24", local.selfip_list[0]), 1)
    vlan-name2    = element(split("/", local.vlan_list[1]), length(split("/", local.vlan_list[1])) - 1)
    self-ip2      = local.selfip_list[1]
  }) : ""
}