variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  //default     = "tf-aws-bigip"
}

variable "f5_username" {
  description = "The admin username of the F5 Bigip that will be deployed"
  default     = "bigipuser"
}

variable "f5_password" {
  description = "Password of the F5 Bigip that will be deployed"
  default     = ""
}

variable "f5_hostname" {
  description = "Custom management hostname. Defaults to managemet public dns."
  type        = string
  default     = ""
}

variable "f5_ami_search_name" {
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 BIGIP-17.1.0.2* PAYG-Best Plus 25Mbps*"
}

variable "ec2_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "m5.xlarge"
}

variable "ec2_key_name" {
  description = "AWS EC2 Key name for SSH access"
  type        = string
}

variable "ebs_volume_encryption" {
  description = "Whether to enable encryption on the EBS volume"
  type        = bool
  default     = false
}

variable "ebs_volume_kms_key_arn" {
  description = "The ARN of the KMS key for volume encryption when using a customer managed key"
  type        = string
  default     = null
}

variable "ebs_volume_type" {
  description = "The EBS volume type to use for the root volume"
  type        = string
  default     = "gp2"
}

variable "aws_secretmanager_auth" {
  description = "Whether to use secret manager to pass authentication"
  type        = bool
  default     = false
}

variable "aws_secretmanager_secret_id" {
  description = "AWS Secret Manager Secret ID that stores the BIG-IP password"
  type        = string
  default     = null
}

variable "aws_iam_instance_profile" {
  description = "aws_iam_instance_profile"
  type        = string
  default     = null
}

variable "mgmt_subnet_ids" {
  description = "The subnet id of the virtual network where the virtual machines will reside."
  type = list(object({
    subnet_id          = string
    public_ip          = bool
    private_ip_primary = string
  }))
  default = [{ "subnet_id" = null, "public_ip" = null, "private_ip_primary" = null }]
}

variable "external_subnet_ids" {
  description = "The subnet id of the virtual network where the virtual machines will reside."
  type = list(object({
    subnet_id            = string
    public_ip            = bool
    private_ip_primary   = string
    private_ip_secondary = string
  }))
  default = [{ "subnet_id" = null, "public_ip" = null, "private_ip_primary" = null, "private_ip_secondary" = null }]
}

variable "internal_subnet_ids" {
  description = "The subnet id of the virtual network where the virtual machines will reside."
  type = list(object({
    subnet_id          = string
    public_ip          = bool
    private_ip_primary = string
  }))
  default = [{ "subnet_id" = null, "public_ip" = null, "private_ip_primary" = null }]
}

variable "internal_source_dest_check" {
  description = "Disable source/dest check on Internal interface to allow inline routing for backends"
  default     = true
}

variable "external_source_dest_check" {
  description = "Disable source/dest check on External interface to allow inline routing for backends"
  default     = false
}

variable "mgmt_securitygroup_ids" {
  description = "The Network Security Group ids for management network "
  type        = list(string)
}

variable "external_securitygroup_ids" {
  description = "The Network Security Group ids for external network "
  type        = list(string)
  default     = []
}

variable "internal_securitygroup_ids" {
  description = "The Network Security Group ids for internal network "
  type        = list(string)
  default     = []
}
## Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable "DO_URL" {
  description = "URL to download the BIG-IP Declarative Onboarding module"
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.38.0/f5-declarative-onboarding-1.38.0-7.noarch.rpm"
}
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable "AS3_URL" {
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.45.0/f5-appsvcs-3.45.0-5.noarch.rpm"
}

## Please check and update the latest TS URL from https://github.com/F5Networks/f5-telemetry-streaming/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable "TS_URL" {
  description = "URL to download the BIG-IP Telemetry Streaming module"
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.33.0/f5-telemetry-1.33.0-1.noarch.rpm"
}

## Please check and update the latest Failover Extension URL from https://github.com/F5Networks/f5-cloud-failover-extension/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable "CFE_URL" {
  description = "URL to download the BIG-IP Cloud Failover Extension module"
  type        = string
  default     = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.14.0/f5-cloud-failover-1.14.0-0.noarch.rpm"
}

## Please check and update the latest FAST URL from https://github.com/F5Networks/f5-appsvcs-templates/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable "FAST_URL" {
  description = "URL to download the BIG-IP FAST module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.24.0/f5-appsvcs-templates-1.24.0-1.noarch.rpm"
}
## Please check and update the latest runtime init URL from https://github.com/F5Networks/f5-bigip-runtime-init/releases/latest
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable "INIT_URL" {
  description = "URL to download the BIG-IP runtime init"
  type        = string
  default     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.6.1/dist/f5-bigip-runtime-init-1.6.1-1.gz.run"
}
variable "libs_dir" {
  description = "Directory on the BIG-IP to download the A&O Toolchain into"
  type        = string
  default     = "/config/cloud/aws/node_modules"
}

variable "onboard_log" {
  description = "Directory on the BIG-IP to store the cloud-init logs"
  type        = string
  default     = "/var/log/startup-script.log"
}

variable "custom_user_data" {
  description = "Provide a custom bash script or cloud-init script the BIG-IP will run on creation"
  type        = string
  default     = null
}

variable "tags" {
  description = "key:value tags to apply to resources built by the module"
  type        = map(any)
  default     = {}
}
variable "externalnic_failover_tags" {
  description = "key:value tags to apply to external nic resources built by the module"
  type        = any
  default     = {}
}

variable "internalnic_failover_tags" {
  description = "key:value tags to apply to internal nic resources built by the module"
  type        = any
  default     = {}
}

variable "cfe_secondary_vip_disable" {
  type        = bool
  description = "Disable Externnal Public IP Association to instance based on this flag (Usecase CFE Scenario)"
  default     = false
}

variable "sleep_time" {
  type        = string
  default     = "600s"
  description = "The number of seconds/minutes of delay to build into creation of BIG-IP VMs; default is 250. BIG-IP requires a few minutes to complete the onboarding process and this value can be used to delay the processing of dependent Terraform resources."
}
