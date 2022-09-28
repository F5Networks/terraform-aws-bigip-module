terraform {
  required_providers {
    bigip = {
      source  = "F5Networks/bigip"
      version = "1.15.1"
    }
  }
}

provider "bigip" {
  address  = format("%s:%s", module.bigip.*.mgmtPublicIP[0], module.bigip.*.mgmtPort[0])
  username = module.bigip.*.f5_username[0]
  password = module.bigip.*.bigip_password[0]
}

resource "bigip_do" "postonboard3nic" {
  count   = var.instance_count
  do_json = module.bigip[count.index].onboard_do
  #   depends_on = [module.bigip]
}

resource "time_sleep" "wait_for_onboardbigip" {
  depends_on      = [bigip_do.postonboard3nic]
  create_duration = "100s"
}

data "bigip_waf_entity_url" "URL" {
  name            = "/graphql"
  protocol        = "http"
  method          = "*"
  perform_staging = true
  type            = "explicit"
}

resource "bigip_waf_policy" "testgraphql" {
  application_language = "utf-8"
  name                 = "testgraphql"
  enforcement_mode     = "blocking"
  template_name        = "POLICY_TEMPLATE_GRAPHQL"
  type                 = "security"
  policy_builder {
    learning_mode = "disabled"
  }
  signatures_settings {
    signature_staging = false
  }
  graphql_profiles {
    name = "graphql_profile"
  }
  file_types {
    name = "php"
    type = "explicit"
  }
  urls       = [data.bigip_waf_entity_url.URL.json]
  signatures = [for k, v in data.bigip_waf_signatures.map : v.json]
  depends_on = [time_sleep.wait_for_onboardbigip]
  # modifications = [local.modifications]
}

# ## GRAPHQL NO PRETECT
# ##
# resource "bigip_as3" "as33" {
#   as3_json = templatefile("DVGATest_nopretect.tpl", {
#     tenant_name = "DVGATest"
#     app_server  = format("%s",aws_instance.webserver.private_ip)
#     app_port    = 9005
#     vs_server   = format("%s",flatten(module.bigip.*.private_addresses[0].public_private.private_ip)[0])
#     policy_ref  = format("/%s/%s", bigip_waf_policy.testgraphql.partition, bigip_waf_policy.testgraphql.name)
#   })
#   depends_on = [bigip_waf_policy.testgraphql,time_sleep.wait_for_onboardbigip]
# }

# GRAPHQL PRETECT
#
resource "bigip_as3" "as33" {
  as3_json = templatefile("DVGATest.tpl", {
    tenant_name = "DVGATest"
    app_server  = format("%s", aws_instance.webserver.private_ip)
    app_port    = 9005
    vs_server   = format("%s", flatten(module.bigip.*.private_addresses[0].public_private.private_ip)[0])
    policy_ref  = format("/%s/%s", bigip_waf_policy.testgraphql.partition, bigip_waf_policy.testgraphql.name)
  })
  depends_on = [bigip_waf_policy.testgraphql, time_sleep.wait_for_onboardbigip]
}
