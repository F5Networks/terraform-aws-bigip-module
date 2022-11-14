terraform {
  required_providers {
    bigip = {
      source = "F5Networks/bigip"
      # version = "1.1.1"
    }
  }
}

provider "bigip" {
  address  = format("%s:%s", module.bigip.*.mgmtPublicIP[0], module.bigip.*.mgmtPort[0])
  username = var.f5_username
  password = random_string.password.result
}

resource "bigip_net_vlan" "vlan1" {
  name = "/Common/external-vlan"
  tag  = 4093
  interfaces {
    tagged   = false
    vlanport = "1.1"
  }
}

resource "bigip_net_vlan" "vlan2" {
  name = "/Common/internal-vlan"
  tag  = 4094

  interfaces {
    tagged   = false
    vlanport = "1.2"
  }
}

resource "bigip_net_selfip" "selfip1" {
  ip            = format("%s/24", flatten(module.bigip.*.private_addresses[0].public_private.private_ip)[0])
  name          = "/Common/external-self"
  traffic_group = "traffic-group-local-only"
  port_lockdown = ["none"]
  vlan          = bigip_net_vlan.vlan1.name
}

resource "bigip_net_selfip" "selfip2" {
  ip            = format("%s/24", flatten(module.bigip.*.private_addresses[0].internal_private.private_ip)[0])
  name          = "/Common/internal-self"
  traffic_group = "traffic-group-local-only"
  port_lockdown = ["default"]
  vlan          = bigip_net_vlan.vlan2.name
}

resource "bigip_net_route" "route" {
  name    = "/Common/default"
  network = "default"
  gw      = cidrhost(bigip_net_selfip.selfip1.ip, 1)
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
  # file_types {
  #   name = "php"
  #   type = "explicit"
  # }
  urls       = [data.bigip_waf_entity_url.URL.json]
  signatures = [for k, v in data.bigip_waf_signatures.map : v.json]
  # depends_on = [time_sleep.wait_for_onboardbigip]
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
#   depends_on = [bigip_waf_policy.testgraphql]
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
  depends_on = [bigip_waf_policy.testgraphql]
}