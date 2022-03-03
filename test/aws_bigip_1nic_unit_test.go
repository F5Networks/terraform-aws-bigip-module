package test

import (
	"crypto/tls"
	// "fmt"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformAWS1NicExample(t *testing.T) {

	t.Parallel()

	terraformOptions := &terraform.Options{

		TerraformDir: "../examples/bigip_aws_1nic_deploy",

		Vars: map[string]interface{}{
			"region": "us-east-1",
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	mgmtPublicIP := terraform.Output(t, terraformOptions, "mgmtPublicIP")
	bigipPassword := terraform.Output(t, terraformOptions, "bigip_password")
	bigipUsername := terraform.Output(t, terraformOptions, "f5_username")
	mgmtPort := terraform.Output(t, terraformOptions, "mgmtPort")
	mgmtPublicURL := terraform.Output(t, terraformOptions, "mgmtPublicURL")

	assert.NotEqual(t, "", mgmtPublicIP[0])
	assert.NotEqual(t, "", bigipPassword[0])
	assert.NotEqual(t, "", bigipUsername[0])

	assert.Equal(t, "8443", string([]byte{mgmtPort[0]}))
	assert.NotEqual(t, "", mgmtPublicURL[0])

	logger.Logf(t, "mgmtPublicURL:%+v",mgmtPublicURL)
	// logger.Logf(t, "bigipPassword:%+v",bigipPassword)

	// fmt.Sprintf("https://%s:%s@%s:%s/mgmt/shared/appsvcs/info", string([]byte{bigipUsername[0]}), string([]byte{bigipPassword[0]}), string([]byte{mgmtPublicIP[0]}), string([]byte{mgmtPort[0]})),

	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	tlsConfig := tls.Config{}

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		string(mgmtPublicURL[0]),
		&tlsConfig,
		10,
		10*time.Second,
		func(statusCode int, body string) bool {
			return statusCode == 200
		},
	)
}

// func verifyNginxIsUp(statusCode int, body string) bool {
// 	return statusCode == 200 && strings.Contains(body, "nginx!")
// }