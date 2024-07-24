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
  domain            = "vpc"
  tags = merge(local.tags, {
    Name = format("%s-%d", "BIGIP-Managemt-PublicIp", count.index)
    }
  )
}

#
# add an elastic IP to the BIG-IP External Public interface
#
resource "aws_eip" "ext-pub" {
  count                     = length(local.external_public_subnet_id)
  network_interface         = length(compact(local.external_public_private_ip_primary)) > 0 ? aws_network_interface.public[count.index].id : aws_network_interface.public1[count.index].id
  domain                    = "vpc"
  associate_with_private_ip = length(compact(local.external_public_private_ip_primary)) > 0 ? aws_network_interface.public[count.index].private_ip : aws_network_interface.public1[count.index].private_ip
  tags = merge(local.tags, var.externalnic_failover_tags, {
    Name = format("%s-%d", "BIGIP-External-PublicIp", count.index)
    }
  )
  depends_on = [aws_eip.mgmt]
}

#
# add an elastic IP to the BIG-IP External interface secondary IP [only for first external public interface]
#
resource "aws_eip" "vip" {
  count = var.cfe_secondary_vip_disable ? 0 : (length(local.external_public_subnet_id) > 0 ? 1 : 0)
  # count                     = var.cfe_secondary_vip_disable ? 0 : (length(local.external_public_subnet_id) > 0 ? (length(compact(local.external_public_private_ip_secondary)) > 0 ? 1 : 0) : 0)
  network_interface         = length(compact(local.external_public_private_ip_primary)) > 0 ? aws_network_interface.public[0].id : aws_network_interface.public1[0].id
  domain                    = "vpc"
  associate_with_private_ip = length(compact(local.external_public_private_ip_primary)) > 0 ? element(compact([for x in tolist(aws_network_interface.public[0].private_ip_list) : x == aws_network_interface.public[0].private_ip ? "" : x]), 0) : element(compact([for x in tolist(aws_network_interface.public1[0].private_ip_list) : x == aws_network_interface.public1[0].private_ip ? "" : x]), 0)
  tags = merge(local.tags, var.externalnic_failover_tags, {
    Name = format("%s-%d", "BIGIP-2ndExternal-PublicIp", count.index)
    }
  )
}

#
# Create Public External Network Interfaces
#
#This resource is for static  primary and secondary private ips

resource "aws_network_interface" "public" {
  count                   = length(compact(local.external_public_private_ip_primary)) > 0 ? length(local.external_public_subnet_id) : 0
  subnet_id               = local.external_public_subnet_id[count.index]
  security_groups         = [local.external_public_security_id[count.index]]
  private_ip_list_enabled = true
  private_ip_list         = compact([local.external_public_private_ip_primary[count.index], local.external_public_private_ip_secondary[count.index]])
  source_dest_check       = var.external_source_dest_check
  tags = merge(local.tags, var.externalnic_failover_tags, {
    Name = format("%s-%d", "BIGIP-External-Public-Interface", count.index)
    }
  )
}

#This resource is for dynamic  primary and secondary private ips

resource "aws_network_interface" "public1" {
  count             = length(compact(local.external_public_private_ip_primary)) > 0 ? 0 : length(local.external_public_subnet_id)
  subnet_id         = local.external_public_subnet_id[count.index]
  security_groups   = [local.external_public_security_id[count.index]]
  source_dest_check = var.external_source_dest_check
  # private_ip_list_enabled = true
  # private_ip_list         = []
  private_ips_count = 1
  tags = merge(local.tags, var.externalnic_failover_tags, {
    Name = format("%s-%d", "BIGIP-External-Public-Interface", count.index)
    }
  )
}

#
# Create Private External Network Interfaces
#
#This resource is for static  primary and secondary private ips

resource "aws_network_interface" "external_private" {
  count                   = length(compact(local.external_private_ip_primary)) > 0 ? length(local.external_private_subnet_id) : 0
  subnet_id               = local.external_private_subnet_id[count.index]
  security_groups         = [local.external_private_security_id[count.index]]
  private_ip_list_enabled = true
  private_ip_list         = compact([local.external_private_ip_primary[count.index], local.external_private_ip_secondary[count.index]])
  source_dest_check       = var.external_source_dest_check
  tags = merge(local.tags, var.externalnic_failover_tags, {
    Name = format("%s-%d", "BIGIP-External-Private-Interface", count.index)
    }
  )
}

#This resource is for dynamic  primary and secondary private ips

resource "aws_network_interface" "external_private1" {
  count             = length(compact(local.external_private_ip_primary)) > 0 ? 0 : length(local.external_private_ip_primary)
  subnet_id         = local.external_private_subnet_id[count.index]
  security_groups   = [local.external_private_security_id[count.index]]
  source_dest_check = var.external_source_dest_check
  # private_ip_list_enabled = true
  # private_ip_list         = []
  private_ips_count = 1
  tags = merge(local.tags, var.externalnic_failover_tags, {
    Name = format("%s-%d", "BIGIP-External-Private-Interface", count.index)
    }
  )
}
#
# Create Private Network Interfaces
#
#This resource is for static  primary and secondary private ips

resource "aws_network_interface" "private" {
  count                   = length(compact(local.internal_private_ip_primary)) > 0 ? length(local.internal_private_subnet_id) : 0
  subnet_id               = local.internal_private_subnet_id[count.index]
  security_groups         = var.internal_securitygroup_ids
  private_ip_list_enabled = true
  private_ip_list         = [local.internal_private_ip_primary[count.index]]
  source_dest_check       = var.internal_source_dest_check
  tags = merge(local.tags, var.internalnic_failover_tags, {
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
  tags = merge(local.tags, var.internalnic_failover_tags, {
    Name = format("%s-%d", "BIGIP-Internal-Interface", count.index)
    }
  )
}

# Deploy BIG-IP
#
resource "aws_instance" "f5_bigip" {
  instance_type = var.ec2_instance_type
  ami           = data.aws_ami.f5_ami.id
  key_name      = var.ec2_key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = var.ebs_volume_encryption
    kms_key_id            = var.ebs_volume_kms_key_arn
    volume_size           = var.ebs_volume_size
    volume_type           = var.ebs_volume_type
  }

  # set the mgmt interface
  dynamic "network_interface" {
    for_each = length(compact(local.mgmt_public_private_ip_primary)) > 0 ? [aws_network_interface.mgmt[0].id] : [aws_network_interface.mgmt1[0].id]
    content {
      network_interface_id = network_interface.value
      device_index         = 0
    }
  }

  # set the public interface only if an interface is defined
  dynamic "network_interface" {
    for_each = length(local.ext_interfaces) > 0 ? local.ext_interfaces : toset([])
    content {
      network_interface_id = network_interface.value
      device_index         = 1 + index(tolist(local.ext_interfaces), network_interface.value)
    }
  }

  # set the private interface only if an interface is defined
  dynamic "network_interface" {
    for_each = length(aws_network_interface.private) > 0 ? [aws_network_interface.private[0].id] : toset([])
    content {
      network_interface_id = network_interface.value
      device_index         = (length(local.ext_interfaces) + 1) + index(tolist([aws_network_interface.private[0].id]), network_interface.value)
    }
  }

  dynamic "network_interface" {
    for_each = length(aws_network_interface.private1) > 0 ? [aws_network_interface.private1[0].id] : toset([])
    content {
      network_interface_id = network_interface.value
      device_index         = (length(local.ext_interfaces) + 1) + index(tolist([aws_network_interface.private1[0].id]), network_interface.value)
    }
  }
  iam_instance_profile = var.aws_iam_instance_profile
  user_data = coalesce(var.custom_user_data, templatefile("${path.module}/templates/f5_onboard.tmpl", {
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
    })
  )
  tags = merge(local.tags, {
    Name = format("BIGIP-Instance-%s", local.instance_prefix)
    }
  )

  dynamic "metadata_options" {
    for_each = var.enable_imdsv2 ? [1] : []
    content {
      http_endpoint = "enabled"
      http_tokens   = "required"
    }
  }

  depends_on = [aws_eip.mgmt, aws_network_interface.public, aws_network_interface.private]
}

resource "time_sleep" "wait_for_aws_instance_f5_bigip" {
  depends_on      = [aws_instance.f5_bigip]
  create_duration = var.sleep_time
}
