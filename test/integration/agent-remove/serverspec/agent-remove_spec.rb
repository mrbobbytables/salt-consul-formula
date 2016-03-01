require 'deep_merge'
require 'serverspec'
require 'yaml'

set :backend, :exec

defaults = YAML.load_file('/tmp/kitchen/srv/salt/consul/defaults.yml')
providermap = YAML.load_file('/tmp/kitchen/srv/salt/consul/providermap.yml')
pillar_data = YAML.load_file('/tmp/kitchen/srv/pillar/consul.sls')
salt_provider = %x(salt-call --local --config-dir=/tmp/kitchen/etc/salt test.provider service)
exec_clean = %x(salt-call --local --config-dir=/tmp/kitchen/etc/salt state.sls consul.agent.remove)

# mimic merge in map.jinja
case salt_provider[/local:\s+(?<provider>\S+)/, :provider] 
when 'debian_service'
  defaults.deep_merge(providermap['debian_service'])
when 'rh_service'
  defaults.deep_merge(providermap['rh_service'])
when 'systemd'
  defaults.deep_merge(providermap['systemd'])
when 'upstart'
  defaults.deep_merge(providermap['upstart'])
end

agent_settings = {}
agent_settings.deep_merge(defaults['agent'])
agent_settings.deep_merge(pillar_data['consul']['lookup']['agent'])

if agent_settings['config']['data_dir']
  agent_settings['data_dir'] = agent_settings['config']['data_dir']
end

if agent_settings['opts']['data-dir']
  agent_settings['data_dir'] = agent_settings['opts']['data-dir'][0]
end




describe 'SLS: consul.agent.remove' do

  describe service('consul') do
    it { should_not be_running }
  end

  describe file(agent_settings['service_def']['name']) do
    it { should_not exist }
  end

  describe file(agent_settings['opts']['config-dir'][0]) do
    it { should_not exist }
  end

  describe file(agent_settings['data_dir']) do
    it { should_not exist }
  end

  describe file(agent_settings['scripts_dir']) do
   it { should_not exist }
  end

  describe file('/usr/local/bin/consul') do
    it {should_not exist }
  end

  describe file("/usr/local/bin/consul-#{agent_settings['pkg']['version']}") do
    it { should_not exist }
  end

end
