## Deploys F5 BIG-IP AWS Cloud

This Terraform module example deploys 1-NIC BIG-IP in AWS, deployed BIGIP will be having management interface associated with user provided subnet and security-group

## Steps to clone and use the module example locally

```shell
git clone https://github.com/f5devcentral/terraform-aws-bigip-module
cd terraform-aws-bigip-module/examples/bigip_aws_1nic_deploy/
```

- Then follow the stated process in Example Usage below

## Example Usage

- Modify `terraform.tfvars` according to the requirement by changing `region` and `AllowedIPs` variables as follows:

    ```hcl
    region = "ap-south-1"
    AllowedIPs = ["0.0.0.0/0"]
    ```

- Next, run the following commands to create and destroy your configuration

    ```shell
    terraform init
    terraform plan
    terraform apply
    terraform destroy
    ```

#### Optional Input Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| prefix | Prefix for resources created by this module | `string` | tf-aws-bigip |
| cidr | aws VPC CIDR | `string` | 10.2.0.0/16 |
| availabilityZones | If you want the VM placed in an Availability Zone, and the AWS region you are deploying to supports it, specify the numbers of the existing Availability Zone you want to use | `List` | ["us-east-1a"] |

#### Output Variables

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

**NOTE:** A local json file will get generated which contains the DO declaration
