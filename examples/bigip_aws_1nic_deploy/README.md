# Deploys F5 BIG-IP AWS Cloud

* This Terraform module example deploys 1-NIC BIG-IP in AWS cloud. 
* Using module `count` feature we can also deploy multiple BIGIP instances(default value of `count` is **1**)
* Management interface associated with user provided **mgmt_subnet_ids** and **mgmt_securitygroup_ids**
* Random generated `password` for login to BIG-IP

## Example Usage

```hcl
module "bigip" {
  source                 = "F5Networks/bigip-module/aws"
  count                  = var.instance_count
  prefix                 = format("%s-1nic", var.prefix)
  ec2_key_name           = aws_key_pair.generated_key.key_name
  f5_password            = random_string.password.result
  mgmt_subnet_ids        = [{ "subnet_id" = aws_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids = [module.mgmt-network-security-group.security_group_id]
}
```

* Modify `terraform.tfvars` according to the requirement by changing `region` and `AllowedIPs` variables as follows:

    ```hcl
    region = "ap-south-1"
    AllowedIPs = ["0.0.0.0/0"]
    ```

* Next, run the following commands to create and destroy your configuration

    ```shell
    $terraform init
    $terraform plan
    $terraform apply
    $terraform destroy
    ```

### Optional Input Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| prefix | Prefix for resources created by this module | `string` | tf-aws-bigip |
| cidr | aws VPC CIDR | `string` | 10.2.0.0/16 |
| availabilityZones | If you want the VM placed in an Availability Zone, and the AWS region you are deploying to supports it, specify the numbers of the existing Availability Zone you want to use | `List` | ["us-east-1a"] |

### Output Variables

| Name | Description |
|------|-------------|
| mgmtPublicIP | The actual ip address allocated for the resource |
| mgmtPublicDNS | fqdn to connect to the first vm provisioned |
| mgmtPort | Mgmt Port |
| f5\_username | BIG-IP username |
| bigip\_password | BIG-IP Password (if dynamic_password is choosen it will be random generated password or if aws_secretmanager_auth is choosen it will be aws_secretsmanager_secret_version secret string ) |
| mgmtPublicURL | Complete url including DNS and port|
| private\_addresses | List of BIG-IP private addresses |
| public\_addresses | List of BIG-IP public addresses |
| vpc\_id | VPC Id where BIG-IP Deployed |

~>**NOTE:** A local json file will get generated which contains the DO declaration

#### Steps to clone and use the module example locally

```shell
$git clone https://github.com/F5Networks/terraform-aws-bigip-module
$cd terraform-aws-bigip-module/examples/bigip_aws_1nic_deploy/
```
