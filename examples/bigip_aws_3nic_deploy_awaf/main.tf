provider "aws" {
  region = var.region
}

#
# Create a random id
#
resource "random_id" "id" {
  byte_length = 2
}

#
# Create random password for BIG-IP
#
resource "random_string" "password" {
  length      = 16
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

#
# Create Secret Store and Store BIG-IP Password
#
resource "aws_secretsmanager_secret" "bigip" {
  name = format("%s-bigip-secret-%s", var.prefix, random_id.id.hex)
}
resource "aws_secretsmanager_secret_version" "bigip-pwd" {
  secret_id     = aws_secretsmanager_secret.bigip.id
  secret_string = random_string.password.result
}

#
# Create the VPC
#
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = format("%s-vpc-%s", var.prefix, random_id.id.hex)
  cidr                 = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs = var.availabilityZones

  tags = {
    Name        = format("%s-vpc-%s", var.prefix, random_id.id.hex)
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "default"
  }
}
resource "aws_route_table" "internet-gw" {
  vpc_id = module.vpc.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_subnet" "mgmt" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = cidrsubnet(var.cidr, 8, 1)
  availability_zone = format("%sa", var.region)

  tags = {
    Name = "management"
  }
}
resource "aws_subnet" "external-public" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = cidrsubnet(var.cidr, 8, 2)
  availability_zone = format("%sa", var.region)

  tags = {
    Name = "external"
  }
}
resource "aws_subnet" "internal" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = cidrsubnet(var.cidr, 8, 3)
  availability_zone = format("%sa", var.region)

  tags = {
    Name = "internal"
  }
}

resource "aws_route_table_association" "route_table_mgmt" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.internet-gw.id
}

resource "aws_route_table_association" "route_table_external" {
  subnet_id      = aws_subnet.external-public.id
  route_table_id = aws_route_table.internet-gw.id
}

resource "aws_route_table_association" "route_table_internal" {
  subnet_id      = aws_subnet.internal.id
  route_table_id = aws_route_table.internet-gw.id
}

#
# Create a security group for BIG-IP
#
module "external-network-security-group-public" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-external-public-nsg-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP "
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.AllowedIPs
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}

#
# Create a security group for BIG-IP Management
#
module "mgmt-network-security-group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-mgmt-nsg-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP Management"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.AllowedIPs
  ingress_rules       = ["https-443-tcp", "https-8443-tcp", "ssh-tcp"]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}

#
# Create a security group for BIG-IP
#
module "internal-network-security-group-public" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-internal-nsg-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP "
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["all-all"]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = format("%s-%s-%s", var.prefix, var.ec2_key_name, random_id.id.hex)
  public_key = tls_private_key.example.public_key_openssh
}

#
# Create BIG-IP
#
module "bigip" {
  source                     = "../../"
  count                      = var.instance_count
  prefix                     = format("%s-3nic", var.prefix)
  ec2_key_name               = aws_key_pair.generated_key.key_name
  f5_ami_search_name         = var.f5_ami_search_name
  mgmt_subnet_ids            = [{ "subnet_id" = aws_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [module.mgmt-network-security-group.security_group_id]
  external_securitygroup_ids = [module.external-network-security-group-public.security_group_id]
  internal_securitygroup_ids = [module.internal-network-security-group-public.security_group_id]
  external_subnet_ids        = [{ "subnet_id" = aws_subnet.external-public.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  internal_subnet_ids        = [{ "subnet_id" = aws_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "" }]
  custom_user_data = templatefile("custom_onboard_big.tmpl", {
    bigip_username         = var.f5_username
    ssh_keypair            = aws_key_pair.generated_key.key_name
    aws_secretmanager_auth = false
    bigip_password         = random_string.password.result
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
  sleep_time = "1000s"
  depends_on = [aws_route_table_association.route_table_mgmt, aws_route_table_association.route_table_external,
    aws_route_table_association.route_table_internal, module.external-network-security-group-public,
  module.internal-network-security-group-public, module.mgmt-network-security-group]
}

resource "aws_instance" "webserver" {
  instance_type               = "t2.large"
  ami                         = "ami-0f9cf087c1f27d9b1"
  key_name                    = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    module.internal-network-security-group-public.security_group_id
  ]
  subnet_id = aws_subnet.internal.id
  user_data = file("init.sh")
  tags = {
    Name = "Webserver"
  }
}

resource "null_resource" "clusterDO" {
  count = var.instance_count
  provisioner "local-exec" {
    command = "cat > DO_3nic-instance${count.index}.json <<EOL\n ${module.bigip[count.index].onboard_do}\nEOL"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf DO_3nic-instance${count.index}.json"
  }
  depends_on = [module.bigip.onboard_do]
}

resource "local_file" "do_onboard" {
  count    = var.instance_count
  content  = module.bigip[count.index].onboard_do
  filename = format("onboard_config-%s.json", count.index)
}

#
# Variables used by this example
#
locals {
  allowed_mgmt_cidr = "0.0.0.0/0"
  allowed_app_cidr  = "0.0.0.0/0"
}

resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = format("%s-%s-%s.pem", var.prefix, var.ec2_key_name, random_id.id.hex)
}