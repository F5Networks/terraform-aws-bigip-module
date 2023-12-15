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
  owners             = ["aws-marketplace"]
  include_deprecated = var.include_deprecated_amis

  filter {
    name   = "description"
    values = [var.f5_ami_search_name]
  }
}