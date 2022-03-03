package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformAWSExample(t *testing.T) {

	t.Parallel()

	terraformOptions := &terraform.Options{

		TerraformDir: "../examples/bigip_aws_2nic_deploy",

		Vars: map[string]interface{}{
			"region": "us-east-1",
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	mgmtPublicIP := terraform.Output(t, terraformOptions, "mgmtPublicIP")
	bigipPassword := terraform.Output(t, terraformOptions, "bigip_password")
	bigipUsername := terraform.Output(t, terraformOptions, "bigip_username")
	mgmtPort := terraform.Output(t, terraformOptions, "mgmtPort")

	assert.NotEqual(t, "", mgmtPublicIP[0])
	assert.NotEqual(t, "", bigipPassword[0])
	assert.NotEqual(t, "", bigipUsername[0])
	assert.Equal(t, "443", mgmtPort[0])

}
