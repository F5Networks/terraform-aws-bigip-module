{
    "class": "AS3",
    "action": "deploy",
    "persist": true,
    "declaration": {
        "class": "ADC",
        "schemaVersion": "3.2.0",
        "id": "Test_DVGA_AS3",
        "${tenant_name}": {
            "class": "Tenant",
            "defaultRouteDomain": 0,
            "DVGA": {
                "class": "Application",
                "template": "generic",
                "VS_DVGA": {
                    "class": "Service_HTTPS",
                    "remark": "Accepts HTTPS/TLS connections on port 443",
                    "virtualAddresses": [
                        "${vs_server}"
                    ],
                    "virtualPort": 8084,
                    "redirect80": false,
                    "pool": "dvga_app_mem",
                    "securityLogProfiles": [
                        {
                            "bigip": "/Common/Log all requests"
                        }
                    ],
                    "profileTCP": {
                        "egress": "wan",
                        "ingress": {
                            "use": "TCP_Profile"
                        }
                    },
                    "profileHTTP": {
                        "use": "custom_http_profile"
                    },
                    "policyWAF": {
                        "bigip": "${policy_ref}"
                    },
                    "serverTLS": {
                        "bigip": "/Common/clientssl"
                    }
                },
                "dvga_app_mem": {
                    "class": "Pool",
                    "monitors": [
                        "http"
                    ],
                    "members": [
                        {
                            "servicePort": ${app_port},
                            "serverAddresses": [
                                "${app_server}"
                            ]
                        }
                    ]
                },
                "custom_http_profile": {
                    "class": "HTTP_Profile",
                    "xForwardedFor": true
                },
                "TCP_Profile": {
                    "class": "TCP_Profile",
                    "idleTimeout": 60
                }
            }
        }
    }
}