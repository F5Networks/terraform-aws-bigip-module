#!/bin/bash

# extract the BIG-IP details from the Terraform output
export BIGIP_MGMT_IP=`terraform output --json | jq -cr '.mgmtPublicIP.value[]'[]`
export BIGIP_USER=`terraform output --json | jq -cr '.f5_username.value[]'`
export BIGIP_PASSWORD=`terraform output --json | jq -cr '.bigip_password.value[]'`
export BIGIP_MGMT_PORT=`terraform output --json | jq -cr '.mgmtPort.value[]'`

#Run InSpect tests from the Jumphost
inspec exec ../inspec/bigip-ready  --input bigip_address=$BIGIP_MGMT_IP bigip_port=$BIGIP_MGMT_PORT user=$BIGIP_USER password=$BIGIP_PASSWORD
