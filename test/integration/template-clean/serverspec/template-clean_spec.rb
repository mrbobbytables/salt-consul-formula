require 'serverspec'

set :backend, :exec

exec_clean = %x(salt-call --local --config-dir=/tmp/kitchen/etc/salt state.sls consul.template.clean)

describe 'SLS: consul.template.clean' do
  describe 'STATE: clean-consul-template-*' do
    describe file("/usr/local/bin/consul-template-0.0.1") do
      it { should_not exist }
    end 
    describe file("/usr/local/bin/consul-template-0.0.2") do
      it { should_not exist }
    end 
  end 
end

