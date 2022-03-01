terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">3.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">2.3.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">2.1.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">2.1.2"
    }
  }
}
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




}

#
# Create a random id
#
resource "random_id" "module_id" {
  byte_length = 2
}

#
# Create random password for BIG-IP
#
resource "random_string" "dynamic_password" {
  //count = var.f5_password == null ? 1 : 0
  length      = 16
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

#
# Ensure Secret exists
#
data "aws_secretsmanager_secret" "password" {
  count = var.aws_secretmanager_auth ? 1 : 0
  name  = var.aws_secretmanager_secret_id
}

data "aws_secretsmanager_secret_version" "current" {
  count     = var.aws_secretmanager_auth ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.password[count.index].id
  //depends_on =[data.aws_secretsmanager_secret.password]
}
#
# Find BIG-IP AMI
#
data "aws_ami" "f5_ami" {
  most_recent = true
  // owners      = ["679593333241"]
  owners = ["aws-marketplace"]

  filter {
    name   = "description"
    values = [var.f5_ami_search_name]
  }
}

#
# Create Management Network Interfaces
#
#This resource is for static  primary and secondary private ips 
resource "aws_network_interface" "mgmt" {
  count           = length(compact(local.mgmt_public_private_ip_primary)) > 0 ? length(local.bigip_map["mgmt_subnet_ids"]) : 0
  subnet_id       = local.bigip_map["mgmt_subnet_ids"][count.index]["subnet_id"]
  private_ips     = [local.mgmt_public_private_ip_primary[count.index]]
  security_groups = var.mgmt_securitygroup_ids
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-Managemt-Interface", count.index)
    }
  )
}

#This resource is for dynamic  primary and secondary private ips  
resource "aws_network_interface" "mgmt1" {
  count             = length(compact(local.mgmt_public_private_ip_primary)) > 0 ? 0 : length(local.bigip_map["mgmt_subnet_ids"])
  subnet_id         = local.bigip_map["mgmt_subnet_ids"][count.index]["subnet_id"]
  security_groups   = var.mgmt_securitygroup_ids
  private_ips_count = 0
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-Managemt-Interface", count.index)
    }
  )
}

#
# add an elastic IP to the BIG-IP management interface
#
resource "aws_eip" "mgmt" {
  count             = length(local.mgmt_public_subnet_id) > 0 ? (length(local.bigip_map["mgmt_subnet_ids"])) : 0
  network_interface = length(compact(local.mgmt_public_private_ip_primary)) > 0 ? aws_network_interface.mgmt[count.index].id : aws_network_interface.mgmt1[count.index].id
  vpc               = true
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-Managemt-PublicIp", count.index)
    }
  )
}

#
# add an elastic IP to the BIG-IP External Public interface
#
resource "aws_eip" "ext-pub" {
  count             = length(local.external_public_subnet_id)
  network_interface = length(compact(local.external_public_private_ip_primary)) > 0 ? aws_network_interface.public[count.index].id : aws_network_interface.public1[count.index].id
  vpc               = true
  depends_on        = [aws_eip.mgmt]
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-External-PublicIp", count.index)
    }
  )
}

#
# add an elastic IP to the BIG-IP External interface secondary IP [only for first external public interface]
#
resource "aws_eip" "vip" {
  count                     = length(local.external_public_subnet_id) > 0 ? 1 : 0
  network_interface         = length(compact(local.external_public_private_ip_primary)) > 0 ? aws_network_interface.public[0].id : aws_network_interface.public1[0].id
  vpc                       = true
  associate_with_private_ip = length(compact(local.external_public_private_ip_primary)) > 0 ? element(compact([for x in tolist(aws_network_interface.public[0].private_ips) : x == aws_network_interface.public[0].private_ip ? "" : x]), 0) : element(compact([for x in tolist(aws_network_interface.public1[0].private_ips) : x == aws_network_interface.public1[0].private_ip ? "" : x]), 0)
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-2ndExternal-PublicIp", count.index)
    }
  )
}

#
# Create Public External Network Interfaces
#
#This resource is for static  primary and secondary private ips

resource "aws_network_interface" "public" {
  count             = length(compact(local.external_public_private_ip_primary)) > 0 ? length(local.external_public_subnet_id) : 0
  subnet_id         = local.external_public_subnet_id[count.index]
  security_groups   = var.external_securitygroup_ids
  private_ips       = [local.external_public_private_ip_primary[count.index], local.external_public_private_ip_secondary[count.index]]
  source_dest_check = var.external_source_dest_check
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-External-Public-Interface", count.index)
    }
  )
}

#This resource is for dynamic  primary and secondary private ips

resource "aws_network_interface" "public1" {
  count             = length(compact(local.external_public_private_ip_primary)) > 0 ? 0 : length(local.external_public_subnet_id)
  subnet_id         = local.external_public_subnet_id[count.index]
  security_groups   = var.external_securitygroup_ids
  source_dest_check = var.external_source_dest_check
  private_ips_count = 1
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-External-Public-Interface", count.index)
    }
  )
}

#
# Create Private External Network Interfaces
#
#This resource is for static  primary and secondary private ips

resource "aws_network_interface" "external_private" {
  count           = length(compact(local.external_private_ip_primary)) > 0 ? length(local.external_private_subnet_id) : 0
  subnet_id       = local.external_private_subnet_id[count.index]
  security_groups = var.external_securitygroup_ids
  private_ips     = [local.external_private_ip_primary[count.index], local.external_private_ip_secondary[count.index]]
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-External-Private-Interface", count.index)
    }
  )
}

#This resource is for dynamic  primary and secondary private ips

resource "aws_network_interface" "external_private1" {
  count             = length(compact(local.external_private_ip_primary)) > 0 ? 0 : length(local.external_private_ip_primary)
  subnet_id         = local.external_private_subnet_id[count.index]
  security_groups   = var.external_securitygroup_ids
  private_ips_count = 1
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-External-Private-Interface", count.index)
    }
  )
}
#
# Create Private Network Interfaces
#
#This resource is for static  primary and secondary private ips

resource "aws_network_interface" "private" {
  count             = length(compact(local.internal_private_ip_primary)) > 0 ? length(local.internal_private_subnet_id) : 0
  subnet_id         = local.internal_private_subnet_id[count.index]
  security_groups   = var.internal_securitygroup_ids
  private_ips       = [local.internal_private_ip_primary[count.index]]
  source_dest_check = var.internal_source_dest_check
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-Internal-Interface", count.index)
    }
  )
}

#This resource is for dynamic  primary and secondary private ips

resource "aws_network_interface" "private1" {
  count             = length(compact(local.internal_private_ip_primary)) > 0 ? 0 : length(local.internal_private_subnet_id)
  subnet_id         = local.internal_private_subnet_id[count.index]
  security_groups   = var.internal_securitygroup_ids
  private_ips_count = 0
  source_dest_check = var.internal_source_dest_check
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-Internal-Interface", count.index)
    }
  )
}

data "template_file" "user_data_vm0" {
  template = file("${path.module}/f5_onboard.tmpl")
  vars = {
    bigip_username         = var.f5_username
    ssh_keypair            = fileexists("~/.ssh/id_rsa.pub") ? file("~/.ssh/id_rsa.pub") : var.ec2_key_name
    aws_secretmanager_auth = var.aws_secretmanager_auth
    bigip_password         = (var.f5_password == "") ? (var.aws_secretmanager_auth ? data.aws_secretsmanager_secret_version.current[0].secret_id : random_string.dynamic_password.result) : var.f5_password
    INIT_URL               = var.INIT_URL,
    DO_URL                 = var.DO_URL,
    DO_VER                 = format("v%s", split("-", split("/", var.DO_URL)[length(split("/", var.DO_URL)) - 1])[3])
    AS3_URL                = var.AS3_URL,
    AS3_VER                = format("v%s", split("-", split("/", var.AS3_URL)[length(split("/", var.AS3_URL)) - 1])[2])
    TS_VER                 = format("v%s", split("-", split("/", var.TS_URL)[length(split("/", var.TS_URL)) - 1])[2])
    TS_URL                 = var.TS_URL,
    CFE_URL                = var.CFE_URL,
    CFE_VER                = format("v%s", split("-", split("/", var.CFE_URL)[length(split("/", var.CFE_URL)) - 1])[3])
    FAST_URL               = var.FAST_URL,
    FAST_VER               = format("v%s", split("-", split("/", var.FAST_URL)[length(split("/", var.FAST_URL)) - 1])[3])
  }
}

# Deploy BIG-IP
#
resource "aws_instance" "f5_bigip" {
  instance_type = var.ec2_instance_type
  ami           = data.aws_ami.f5_ami.id
  key_name      = var.ec2_key_name

  root_block_device {
    delete_on_termination = true
  }

  # set the mgmt interface
  dynamic "network_interface" {
    for_each = length(compact(local.mgmt_public_private_ip_primary)) > 0 ? toset([aws_network_interface.mgmt[0].id]) : toset([aws_network_interface.mgmt1[0].id])
    content {
      network_interface_id = network_interface.value
      device_index         = 0
    }
  }

  # set the public interface only if an interface is defined
  dynamic "network_interface" {
    for_each = length(local.ext_interfaces) > 0 ? toset(local.ext_interfaces) : toset([])
    content {
      network_interface_id = network_interface.value
      device_index         = 1 + index(tolist(toset(local.ext_interfaces)), network_interface.value)
    }
  }

  # set the private interface only if an interface is defined
  dynamic "network_interface" {
    for_each = length(aws_network_interface.private) > 0 ? toset([aws_network_interface.private[0].id]) : toset([])
    content {
      network_interface_id = network_interface.value
      device_index         = (length(local.ext_interfaces) + 1) + index(tolist(toset([aws_network_interface.private[0].id])), network_interface.value)
    }
  }

  dynamic "network_interface" {
    for_each = length(aws_network_interface.private1) > 0 ? toset([aws_network_interface.private1[0].id]) : toset([])
    content {
      network_interface_id = network_interface.value
      device_index         = (length(local.ext_interfaces) + 1) + index(tolist(toset([aws_network_interface.private1[0].id])), network_interface.value)
    }
  }
  iam_instance_profile = var.aws_iam_instance_profile
  user_data            = coalesce(var.custom_user_data, data.template_file.user_data_vm0.rendered)
  tags = merge(local.tags, {
    Name = format("BIGIP-Instance-%s", local.instance_prefix)
    }
  )
  depends_on = [aws_eip.mgmt, aws_network_interface.public, aws_network_interface.private]
}

resource "time_sleep" "wait_for_aws_instance_f5_bigip" {
  depends_on      = [aws_instance.f5_bigip]
  create_duration = var.sleep_time
}

data "template_file" "clustermemberDO1" {
  count    = local.total_nics == 1 ? 1 : 0
  template = file("${path.module}/onboard_do_1nic.tpl")
  vars = {
    hostname      = length(aws_eip.mgmt) > 0 ? aws_eip.mgmt[0].public_dns : ""
    name_servers  = join(",", formatlist("\"%s\"", ["169.254.169.253"]))
    search_domain = "f5.com"
    ntp_servers   = join(",", formatlist("\"%s\"", ["169.254.169.123"]))
  }
}

data "template_file" "clustermemberDO2" {
  count    = local.total_nics == 2 ? 1 : 0
  template = file("${path.module}/onboard_do_2nic.tpl")
  vars = {
    hostname      = length(aws_eip.mgmt) > 0 ? aws_eip.mgmt[0].public_dns : ""
    name_servers  = join(",", formatlist("\"%s\"", ["169.254.169.253"]))
    search_domain = "f5.com"
    ntp_servers   = join(",", formatlist("\"%s\"", ["169.254.169.123"]))
    vlan-name     = element(split("/", local.vlan_list[0]), length(split("/", local.vlan_list[0])) - 1)
    self-ip       = local.selfip_list[0]
    gateway       = cidrhost(format("%s/24", local.selfip_list[0]), 1)
  }
  depends_on = [aws_network_interface.public, aws_network_interface.private]
}

data "template_file" "clustermemberDO3" {
  count    = local.total_nics >= 3 ? 1 : 0
  template = file("${path.module}/onboard_do_3nic.tpl")
  vars = {
    hostname      = length(aws_eip.mgmt) > 0 ? aws_eip.mgmt[0].public_dns : ""
    name_servers  = join(",", formatlist("\"%s\"", ["169.254.169.253"]))
    search_domain = "f5.com"
    ntp_servers   = join(",", formatlist("\"%s\"", ["169.254.169.123"]))
    vlan-name1    = element(split("/", local.vlan_list[0]), length(split("/", local.vlan_list[0])) - 1)
    self-ip1      = local.selfip_list[0]
    gateway       = cidrhost(format("%s/24", local.selfip_list[0]), 1)
    vlan-name2    = element(split("/", local.vlan_list[1]), length(split("/", local.vlan_list[1])) - 1)
    self-ip2      = local.selfip_list[1]
  }
  depends_on = [aws_network_interface.public, aws_network_interface.private]
}
