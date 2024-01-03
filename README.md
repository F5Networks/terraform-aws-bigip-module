# Deploys BIG-IP in AWS Cloud

This Terraform module deploys N-nic F5 BIG-IP in AWS cloud,and with module `count` feature we can also deploy multiple instances of BIG-IP.

## Prerequisites

This module is supported from Terraform 0.13 version onwards.

It is tested against following provider/terraform versions

Terraform v1.1.8

+ provider registry.terraform.io/hashicorp/aws v4.32.0
+ provider registry.terraform.io/hashicorp/random v3.4.3
+ provider registry.terraform.io/hashicorp/time v0.8.0
+ provider registry.terraform.io/hashicorp/null v3.1.1

## Releases and Versioning

This module is supported in the following bigip and terraform version

| BIGIP version | Terraform 1.X | Terraform 0.14 |
|---------------|----------------|----------------|
| BIG-IP 17.x   |      X         |      X         |
| BIG-IP 16.x   |      X         |      X         |
| BIG-IP 15.x   |      X         |      X         |

## Password Management

~> **NOTE:** By default bigip module will have random password setting to give dynamic password generation

~> **NOTE:** Users Can explicitly provide password as input to Module using optional Variable "f5_password"

~> **NOTE** To use AWS secret manager password,we have to enable the variable "aws_secretmanager_auth" to true and supply the secret name to variable "aws_secretmanager_secret_id" and also IAM Profile to "aws_iam_instance_profile"

~> **NOTE** End Users are responsible of the IAM profile setup, please find useful links for [IAM Setup](https://aws.amazon.com/premiumsupport/knowledge-center/restrict-ec2-iam/)

## BYOL Licensing

This Module uses PayGo BIG-IP image for the deployment (`default`). If you would like to use BYOL licenses, then these following steps are needed:

+ Find available images/versions with *BYOL* in SKU name using AWS CLI:

    ```sh
    aws ec2 describe-images --owners 679593333241 --filters "Name=name, Values=*BIGIP-16.1.3*BYOL*"
    ```

  Ex: `"aws-marketplace/F5 BIGIP-16.1.3-0.0.12 BYOL-All Modules 2Boot Loc-220607230313-5f5a1994-65df-4235-b79c-a3ea049dc1db"`

+ In the `variables.tf`, modify `f5_ami_search_name` with the filter value like `Name=name, Values=*BIGIP-16.1.3*BYOL*`

+ Add the corresponding `Registrationkeylicense key` in DO declaration( Declarative Onboarding ), this DO can be added in custom run-time-int script ( as given in examples section ) or POST a Declarative Onboarding declaration as given in [DO](https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/bigip-examples.html#standalone-declaration)

    ```shell
    "myLicense": {
      "class": "License",
      "licenseType": "regKey",
      "regKey": "${regKey}"
    },
    ```

## Custom User data

+ By default `custom_user_data` will be null,bigip module will use default f5_onboard.tmpl file contents for initial BIGIP onboard connfiguration

+ If users desire custom onboard configuration,we can use this variable and pass contents of custom script to the variable to have custom onboard bigip  configuration.( An example is provided in examples section )

```hcl
module bigip {
  source                      = "F5Networks/bigip-module/aws"
  prefix                      = "bigip-aws-3nic"
  ec2_key_name                = aws_key_pair.generated_key.key_name
  mgmt_subnet_ids             = [{ "subnet_id" = "subnet_id_mgmt", "public_ip" = true, "private_ip_primary" =  ""}]
  mgmt_securitygroup_ids      = ["securitygroup_id_mgmt"]
  external_subnet_ids         = [{ "subnet_id" = "subnet_id_external", "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = ""}]
  external_securitygroup_ids  = ["securitygroup_id_external"]
  internal_subnet_ids         = [{"subnet_id" =  "subnet_id_internal", "public_ip"=false, "private_ip_primary" = ""}]
  internal_securitygroup_ids  = ["securitygropu_id_internal"]
  custom_user_data       = var.custom_user_data
}
```

## Example Usage

We have provided some common deployment [examples](https://github.com/F5Networks/terraform-aws-bigip-module/tree/main/examples)

!> **NOTE:** There should be one to one mapping between subnet_ids and securitygroup_ids (for example if we have 2 or more external subnet_ids,we have to give same number of external securitygroup_ids to module)

!> **NOTE:** Users can have dynamic or static private ip allocation.If primary/secondary private ip value is null it will be dynamic,else it will be static private ip allocation.

!> **NOTE:** With Static private ip allocation we can assign primary and secondary private ips for external interfaces, whereas primary private ip for management and internal interfaces.

!> **NOTE:** If it is static private ip allocation we can't use module count as same private ips will be tried to allocate for multiple bigip instances based on module count.

~> **WARNING** With Dynamic private ip allocation,we have to pass null value to primary/secondary private ip declaration and module count will be supported.

!> **NOTE:** Sometimes it is observed that the given static primary and secondary private ips may get exchanged. This is the limitation present in aws.

~>**NOTE:** If you are using custom ATC tools, don't change name of ATC tools rpm file( ex: f5-declarative-onboarding-xxxx.noarch.rpm,f5-appsvcs-xxx.noarch.rpm)

### Below example snippets show how this module is called (Dynamic private ip allocation )

```hcl
#
#Example 1-NIC Deployment Module usage
#
module bigip {
  source                 = "F5Networks/bigip-module/aws"
  prefix                 = "bigip-aws-1nic"
  ec2_key_name           = aws_key_pair.generated_key.key_name
  mgmt_subnet_ids        = [{ "subnet_id" = "subnet_id_mgmt", "public_ip" = true, "private_ip_primary" =  ""}]
  mgmt_securitygroup_ids = ["securitygroup_id_mgmt"]
}

#
#Example 2-NIC Deployment Module usage
#
module bigip {
  source                      = "F5Networks/bigip-module/aws"
  prefix                      = "bigip-aws-2nic"
  ec2_key_name                = aws_key_pair.generated_key.key_name
  mgmt_subnet_ids             = [{ "subnet_id" = "subnet_id_mgmt", "public_ip" = true, "private_ip_primary" =  ""}]
  mgmt_securitygroup_ids      = ["securitygroup_id_mgmt"]
  external_subnet_ids         = [{ "subnet_id" = "subnet_id_external", "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = ""}]
  external_securitygroup_ids  = ["securitygroup_id_external"]
}

#
#Example 3-NIC Deployment  Module usage
#
module bigip {
  source                      = "F5Networks/bigip-module/aws"
  prefix                      = "bigip-aws-3nic"
  ec2_key_name                = aws_key_pair.generated_key.key_name
  mgmt_subnet_ids             = [{ "subnet_id" = "subnet_id_mgmt", "public_ip" = true, "private_ip_primary" =  ""}]
  mgmt_securitygroup_ids      = ["securitygroup_id_mgmt"]
  external_subnet_ids         = [{ "subnet_id" = "subnet_id_external", "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = ""}]
  external_securitygroup_ids  = ["securitygroup_id_external"]
  internal_subnet_ids         = [{"subnet_id" =  "subnet_id_internal", "public_ip"=false, "private_ip_primary" = ""}]
  internal_securitygroup_ids  = ["securitygropu_id_internal"]
}

#
#Example 4-NIC Deployment  Module usage(with 2 external public interfaces,one management and internal interface.There should be one to one mapping between subnet_ids and securitygroupids)
#

module bigip {
  source                      = "F5Networks/bigip-module/aws"
  prefix                      = "bigip-aws-4nic"
  ec2_key_name                = aws_key_pair.generated_key.key_name
  mgmt_subnet_ids             = [{ "subnet_id" = "subnet_id_mgmt", "public_ip" = true }]
  mgmt_securitygroup_ids      = ["securitygroup_id_mgmt"]
  external_subnet_ids         = [{ "subnet_id" = "subnet_id_external", "public_ip" = true },{"subnet_id" =  "subnet_id_external2", "public_ip" = true }]
  external_securitygroup_ids  = ["securitygroup_id_external","securitygroup_id_external"]
  internal_subnet_ids         = [{"subnet_id" =  "subnet_id_internal", "public_ip"=false }]
  internal_securitygroup_ids  = ["securitygropu_id_internal"]
}

#
#Example to deploy 2 BIGIP-1 Nics using Module with module count feature
#
module bigip {
  count                  = 2
  source                 = "F5Networks/bigip-module/aws"
  prefix                 = "bigip-aws-1nic"
  ec2_key_name           = aws_key_pair.generated_key.key_name
  mgmt_subnet_ids        = [{ "subnet_id" = "subnet_id_mgmt", "public_ip" = true, "private_ip_primary" =  ""}]
  mgmt_securitygroup_ids = ["securitygroup_id_mgmt"]
}

```

+ Similarly we can have N-nic deployments based on user provided subnet_ids and securitygroup_ids

+ With module count, user can deploy multiple bigip instances in the aws cloud (with the default value of count being one )

#### Below is the example snippet for private ip allocation

```hcl
#
#Example 3-NIC Deployment with static private ip allocation
#
module bigip {
  source                      = "F5Networks/bigip-module/aws"
  prefix                      = format("%s-3nic", var.prefix)
  ec2_key_name                = aws_key_pair.generated_key.key_name
  aws_secretmanager_secret_id = aws_secretsmanager_secret.bigip.id
  mgmt_subnet_ids             = [{ "subnet_id" = aws_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "10.0.1.4"}]
  mgmt_securitygroup_ids      = [module.mgmt-network-security-group.this_security_group_id]
  external_securitygroup_ids  = [module.external-network-security-group-public.this_security_group_id]
  internal_securitygroup_ids  = [module.internal-network-security-group-public.this_security_group_id]
  external_subnet_ids         = [{ "subnet_id" = aws_subnet.external-public.id, "public_ip" = true, "private_ip_primary" = "10.0.2.4", "private_ip_secondary" = "10.0.2.5"}]
  internal_subnet_ids         = [{ "subnet_id" = aws_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "10.0.3.4"}]
}
```

### Required Input Variables

These variables must be set in the module block when using this module.

| Name | Description | Type |
|------|-------------|------|
| prefix | This value is inserted in the beginning of each aws object. Note: requires alpha-numeric without special character | `string` |
| ec2_key_name  | AWS EC2 Key name for SSH access,managing key is out of band module, user can reference this key name from [aws_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | `string`  |   |
| mgmt\_subnet\_ids | Map with Subnet-id and public_ip as keys for the management subnet | `List of Maps` |
| mgmt\_securitygroup\_ids | securitygroup\_ids for the management interface | `List` |

### Optional Input Variables

These variables have default values and don't have to be set to use this module. You may set these variables to override their default values.

| Name | Description | Type | Default |
|------|-------------|------|---------|
| f5\_username | The admin username of the F5   BIG-IP that will be deployed | `string` | bigipuser |
| f5\_password | Password of the F5  BIG-IP that will be deployed | `string` | "" |
| f5\_hostname | Custom management hostname. Defaults to managemet public dns | `string` | "" |
| ec2_instance_type  | AWS EC2 instance type  | `string`  | m5.large  |
| ebs_volume_encryption  | Whether to enable encryption on the EBS volume  | `bool`  | false  |
| ebs_volume_kms_key_arn  | The ARN of the KMS key for volume encryption when using a customer managed key  | `string`  |      |
| ebs_volume_type  | The EBS volume type to use for the root volume  | `string`  | gp2   |
| ebs_volume_size  | Size of the volume in gibibytes (GiB)  | `number`  | 82  |
| f5_ami_search_name  | BIG-IP AMI name to search for  | `string`  | F5 BIGIP-*PAYG-Best 200Mbps*  |
| aws_secretmanager_auth  | Whether to use key vault to pass authentication  | `bool`  | false  |
| aws_secretmanager_secret_id  | AWS Secret Manager Secret ID that stores the BIG-IP password  | `string`  |   |
| aws_iam_instance_profile  | AWS IAM instance profile that can be associate for BIGIP with required permissions  | `string`  |   |
| DO_URL | URL to download the BIG-IP Declarative Onboarding module | `string` | `latest` Note: don't change name of ATC tools rpm file |
| AS3_URL | URL to download the BIG-IP Application Service Extension 3 (AS3) module | `string` | `latest` Note: don't change name of ATC tools rpm file |
| TS_URL | URL to download the BIG-IP Telemetry Streaming module | `string` | `latest` Note: don't change name of ATC tools rpm file |
| FAST_URL | URL to download the BIG-IP FAST module | `string` | `latest` Note: don't change name of ATC tools rpm file |
| CFE_URL | URL to download the BIG-IP Cloud Failover Extension module | `string` | `latest` Note: don't change name of ATC tools rpm file |
| INIT_URL | URL to download the BIG-IP runtime init module | `string` | `latest` Note: don't change name of ATC tools rpm file |
| libs\_dir | Directory on the BIG-IP to download the A&O Toolchain into | `string` | /config/cloud/aws/node_modules |
| custom\_user\_data | Provide a custom bash script or cloud-init script the BIG-IP will run on creation | `string`  |   null   |
| onboard\_log | Directory on the BIG-IP to store the cloud-init logs | `string` | /var/log/startup-script.log |
| external\_subnet\_ids | he subnet id of the virtual network where the virtual machines will reside | `List of Maps` | [{ "subnet_id" = null, "public_ip" = null }] |
| internal\_subnet\_ids | The subnet id of the virtual network where the virtual machines will reside | `List of Maps` | [{ "subnet_id" = null, "public_ip" = null }] |
| external\_securitygroup\_ids | The Network Security Group ids for external network | `List` | [] |
| internal\_securitygroup\_ids | The Network Security Group ids for internal network | `List` | [] |
| tags | `key:value` tags to apply to resources built by the module | `map`  |   {}   |
| externalnic_failover_tags | `key:value` tags to apply to external nic resources built by the module | `map`  |   {}   |
| internalnic_failover_tags | `key:value` tags to apply to external nic resources built by the module | `map`  |   {}   |
| cfe_secondary_vip_disable  | Disable Externnal Public IP Association to instance based on this flag (Usecase CFE Scenario) | `bool`  | `false`  |
| include_deprecated_amis  | Whether or not to include deprecated AMIs when performing the AMI search | `bool`  | `false`  |
| sleep_time | The number of seconds/minutes of delay to build into creation of BIG-IP VMs | `string` | 300s |

~> **NOTE:** For each external interface there will be one primary,secondary private ip will be assigned.

### Output Variables

| Name | Description |
|------|-------------|
| mgmtPublicIP | The actual ip address allocated for the resource |
| mgmtPublicDNS | fqdn to connect to the first vm provisioned |
| mgmtPort | Mgmt Port |
| f5\_username | BIG-IP username |
| bigip\_password | BIG-IP Password (if dynamic_password is choosen it will be random generated password or if aws_secretmanager_auth is choosen it will be aws_secretsmanager_secret_version secret string ) |
| private\_addresses | It is List of Maps all privates address assigned for Mgmt/External-Public/External-private/Internal|
| public\_addresses | It is List of Maps all public address assigned for External-public-primary/ External-public-secondary|
| bigip\_instance\_ids | List of BIG-IP AWS Instance IDs Created |
| bigip\_nic\_ids | List of BIG-IP network interface IDs |

~ **NOTE:** IF you want to access External interface private IPs, you need to filter it form `private_addresses` map like below:

```hcl
  output "external_public_primary_private_ip" {
    description = "List of BIG-IP private addresses"
    value       = flatten([for i in range(length(module.bigip.*.private_addresses)) : module.bigip.*.private_addresses[i]["public_private"]["private_ip"]])
  }
```

~> **NOTE:** A local json file will get generated which contains the DO declaration

### BIG-IP Automation Toolchain InSpec Profile for testing readiness of Automation Tool Chain components

After the module deployment, we can use inspec tool for verifying the Bigip connectivity along with ATC components

This InSpec profile evaluates the following:

+ Basic connectivity to a BIG-IP management endpoint ('bigip-connectivity')
+ Availability of the Declarative Onboarding (DO) service ('bigip-declarative-onboarding')
+ Version reported by the Declarative Onboarding (DO) service ('bigip-declarative-onboarding-version')
+ Availability of the Application Services (AS3) service ('bigip-application-services')
+ Version reported by the Application Services (AS3) service ('bigip-application-services-version')
+ Availability of the Telemetry Streaming (TS) service ('bigip-telemetry-streaming')
+ Version reported by the Telemetry Streaming (TS) service ('bigip-telemetry-streaming-version')
+ Availability of the Cloud Failover Extension( CFE ) service ('bigip-cloud-failover-extension')
+ Version reported by the Cloud Failover Extension( CFE ) service('bigip-cloud-failover-extension-version')

#### run inspec tests

we can either run inspec exec command or execute runtests.sh in any one of example nic folder which will run below inspec command

```bash
inspec exec inspec/bigip-ready  --input bigip_address=$BIGIP_MGMT_IP bigip_port=$BIGIP_MGMT_PORT user=$BIGIP_USER password=$BIGIP_PASSWORD do_version=$DO_VERSION as3_version=$AS3_VERSION ts_version=$TS_VERSION fast_version=$FAST_VERSION cfe_version=$CFE_VERSION
```

## Support Information

This repository is community-supported. Follow instructions below on how to raise issues.

### Filing Issues and Getting Help

If you come across a bug or other issue, use [GitHub Issues](https://github.com/F5Networks/terraform-aws-bigip-module/issues) to submit an issue for our team.  You can also see the current known issues on that page, which are tagged with a purple Known Issue label.

## Copyright

Copyright 2014-2019 F5 Networks Inc.

### F5 Networks Contributor License Agreement

Before you start contributing to any project sponsored by F5 Networks, Inc. (F5) on GitHub, you will need to sign a Contributor License Agreement (CLA).

If you are signing as an individual, we recommend that you talk to your employer (if applicable) before signing the CLA since some employment agreements may have restrictions on your contributions to other projects. Otherwise by submitting a CLA you represent that you are legally entitled to grant the licenses recited therein.

If your employer has rights to intellectual property that you create, such as your contributions, you represent that you have received permission to make contributions on behalf of that employer, that your employer has waived such rights for your contributions, or that your employer has executed a separate CLA with F5.

If you are signing on behalf of a company, you represent that you are legally entitled to grant the license recited therein. You represent further that each employee of the entity that submits contributions is authorized to submit such contributions on behalf of the entity pursuant to the CLA.