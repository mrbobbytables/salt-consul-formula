require 'deep_merge'
require 'serverspec'
require 'yaml'

set :backend, :exec

defaults = YAML.load_file('/tmp/kitchen/srv/salt/consul/defaults.yml')
providermap = YAML.load_file('/tmp/kitchen/srv/salt/consul/providermap.yml')
pillar_data = YAML.load_file('/tmp/kitchen/srv/pillar/consul.sls')
salt_provider = %x(salt-call --local --config-dir=/tmp/kitchen/etc/salt test.provider service)
exec_remove = %x(salt-call --local --config-dir=/tmp/kitchen/etc/salt state.sls consul.template.remove)

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

template_settings = {}
template_settings.deep_merge(defaults['template'])
template_settings.deep_merge(pillar_data['consul']['lookup']['template'])


describe 'SLS: consul.template.remove' do

  describe service('consul-template') do
    it { should_not be_running }
  end

  describe file(template_settings['service_def']['name']) do
    it { should_not exist }
  end

  describe file(template_settings['opts']['config'][0]) do
    it { should_not exist }
  end

  describe file(template_settings['templates_dir']) do
   it { should_not exist }
  end

  describe file('/usr/local/bin/consul-template') do
    it {should_not exist }
  end

  describe file("/usr/local/bin/consul-#{template_settings['pkg']['version']}") do
    it { should_not exist }
  end

  describe file('/usr/local/bin/consul-template-0.0.1') do
    it { should_not exist }
  end

  describe file('/usr/local/bin/consul-template-0.0.2') do
    it { should_not exist }
  end
end
