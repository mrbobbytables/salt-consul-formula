require 'serverspec'

set :backend, :exec

exec_clean = %x(salt-call --local --config-dir=/tmp/kitchen/etc/salt state.sls consul.agent.clean)

describe 'SLS: consul.agent.clean' do
  describe 'STATE: clean-consul-agent-*' do
    describe file("/usr/local/bin/consul-0.0.1") do
      it { should_not exist }
    end 
    describe file("/usr/local/bin/consul-0.0.2") do
      it { should_not exist }
    end 
  end 
end

