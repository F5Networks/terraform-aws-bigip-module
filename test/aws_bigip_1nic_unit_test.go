package test

import (
	"crypto/tls"
	"fmt"
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

	mgmtPublicIP = mgmtPublicIP[1 : len(mgmtPublicIP)-1]
	bigipPassword = bigipPassword[1 : len(bigipPassword)-1]
	bigipUsername = bigipUsername[1 : len(bigipUsername)-1]
	mgmtPort = mgmtPort[1 : len(mgmtPort)-1]
	mgmtPublicURL = mgmtPublicURL[1 : len(mgmtPublicURL)-1]

	assert.NotEqual(t, "", mgmtPublicIP)
	assert.NotEqual(t, "", bigipPassword)
	assert.NotEqual(t, "", bigipUsername)
	assert.Equal(t, "8443", mgmtPort)
	assert.NotEqual(t, "", mgmtPublicURL)

	logger.Logf(t, "mgmtPublicURL:%+v", mgmtPublicURL)
	logger.Logf(t, "bigipPassword:%+v", bigipPassword)

	assert.NotEqual(t, "", mgmtPublicIP)
	assert.NotEqual(t, "", bigipPassword)
	assert.NotEqual(t, "", bigipUsername)
	assert.Equal(t, "8443", mgmtPort)
	assert.NotEqual(t, "", mgmtPublicURL)

	logger.Logf(t, "mgmtPublicURL:%+v", mgmtPublicURL)
	// logger.Logf(t, "bigipPassword:%+v",bigipPassword)

	testUrl := fmt.Sprintf("https://%s:%s@%s:%s/mgmt/shared/appsvcs/info", bigipUsername, bigipPassword, mgmtPublicIP, mgmtPort)

	logger.Logf(t, "testUrl:%+v", testUrl)

	// fmt.Sprintf("https://%s:%s@%s:%s/mgmt/shared/appsvcs/info", string([]byte{bigipUsername[0]}), string([]byte{bigipPassword[0]}), string([]byte{mgmtPublicIP[0]}), string([]byte{mgmtPort[0]})),

	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	tlsConfig := tls.Config{}

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		testUrl,
		&tlsConfig,
		20,
		10*time.Second,
		func(statusCode int, body string) bool {
			return statusCode == 200
		},
	)
}

// func verifyNginxIsUp(statusCode int, body string) bool {
// 	return statusCode == 200 && strings.Contains(body, "nginx!")
// }
