title "Verify BIG-IP Automation Toolchain is installed and ready"

BIGIP_HOST     = input('bigip_address')
BIGIP_PORT     = input('bigip_port')
BIGIP_USER     = input('user')
BIGIP_PASSWORD = input('password')

control "bigip-connectivity" do
  impact 1.0
  title "BIG-IP is reachable"
  describe host(BIGIP_HOST, port: BIGIP_PORT, protocol: 'tcp') do
      it { should be_reachable }
  end
end 

control "bigip-declarative-onboarding" do
  impact 1.0
  title "BIG-IP has Declarative Onboarding"
  # is the declarative onboarding end point available?
  describe http("https://#{BIGIP_HOST}:#{BIGIP_PORT}/mgmt/shared/declarative-onboarding/info",
            auth: {user: BIGIP_USER, pass: BIGIP_PASSWORD},
            method: 'GET',
            ssl_verify: false) do
        its('status') { should cmp 200 }
        its('headers.Content-Type') { should match 'application/json' }
  end
end 

control "bigip-application-services" do
  impact 1.0
  title "BIG-IP has Application Services"
  describe http("https://#{BIGIP_HOST}:#{BIGIP_PORT}/mgmt/shared/appsvcs/info",
            auth: {user: BIGIP_USER, pass: BIGIP_PASSWORD},
            method: 'GET',
            ssl_verify: false) do
        its('status') { should cmp 200 }
        its('headers.Content-Type') { should match 'application/json' }
  end
end 

control "bigip-telemetry-streaming" do
  impact 1.0
  title "BIG-IP has Telemetry Streaming"
  describe http("https://#{BIGIP_HOST}:#{BIGIP_PORT}/mgmt/shared/telemetry/info",
            auth: {user: BIGIP_USER, pass: BIGIP_PASSWORD},
            method: 'GET',
            ssl_verify: false) do
        its('status') { should cmp 200 }
        its('headers.Content-Type') { should match 'application/json' }
  end
end 

control "bigip-fast" do
  impact 1.0
  title "BIG-IP has F5 Application Service Templates"
  describe http("https://#{BIGIP_HOST}:#{BIGIP_PORT}/mgmt/shared/fast/info",
            auth: {user: BIGIP_USER, pass: BIGIP_PASSWORD},
            method: 'GET',
            ssl_verify: false) do
        its('status') { should cmp 200 }
        its('headers.Content-Type') { should match 'application/json' }
  end
end 

control "bigip-cloud-failover-extension" do
  impact 1.0
  title "BIG-IP has F5 Cloud Failover Extension"
  describe http("https://#{BIGIP_HOST}:#{BIGIP_PORT}/mgmt/shared/cloud-failover/info",
            auth: {user: BIGIP_USER, pass: BIGIP_PASSWORD},
            method: 'GET',
            ssl_verify: false) do
        its('status') { should cmp 200 }
        its('headers.Content-Type') { should match 'application/json' }
  end
end 

control "bigip-licensed" do
  impact 1.0
  title "BIG-IP has an active license"
  describe http("https://#{BIGIP_HOST}:#{BIGIP_PORT}/mgmt/tm/sys/license",
            auth: {user: BIGIP_USER, pass: BIGIP_PASSWORD },
            method: 'GET',
            ssl_verify: false) do
    its('body') { should match /registrationKey/ }
  end
end
