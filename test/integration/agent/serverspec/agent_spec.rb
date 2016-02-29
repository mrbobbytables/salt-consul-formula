require 'deep_merge'
require 'json'
require 'json_spec'
require 'rspec'
require 'serverspec'
require 'yaml'

set :backend, :exec

defaults = YAML.load_file('/tmp/kitchen/srv/salt/consul/defaults.yml')
providermap = YAML.load_file('/tmp/kitchen/srv/salt/consul/providermap.yml')
pillar_data = YAML.load_file('/tmp/kitchen/srv/pillar/consul.sls')
salt_provider = %x(salt-call --local --config-dir=/tmp/kitchen/etc/salt test.provider service)
salt_osarch = %x(salt-call --local --config-dir=/tmp/kitchen/etc/salt grains.get osarch)
salt_kernel = %x(salt-call --local --config-dir=/tmp/kitchen/etc/salt grains.get kernel)
kernel = salt_kernel[/local:\s+(?<kernel>\S+)/, :kernel].downcase


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


case salt_osarch[/^local:\s+(?<osarch>\S+)\z/, :osarch]
when 'amd64', 'x86_64'
  osarch = 'amd64'
else
  osarch = salt_osarch[/local:\s+(?<osarch>\S+)/, :osarch].downcase
end

if agent_settings['config']['data_dir']
  agent_settings['data_dir'] = agent_settings['config']['data_dir']
end

if agent_settings['opts']['data-dir']
  agent_settings['data_dir'] = agent_settings['opts']['data-dir'][0]
end

pkg_path = '/tmp/consul_' + agent_settings['pkg']['version'] + '_' + kernel + '_' + osarch + '.zip'


# consul.prereqs
describe user('consul') do
  it { should exist }
end

describe group('consul') do
  it { should exist }
end

# consul.install

describe file('/usr/local/bin/consul') do
  it { should exist }
  it { should be_symlink }
  it { should be_executable }
end

describe file('/usr/local/bin/consul-' + agent_settings['pkg']['version']) do
  it { should exist }
  it { should be_file }
  it { should be_executable }
end

describe file(pkg_path) do
  it { should_not exist }
end

describe file(agent_settings['opts']['config-dir'][0]) do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'consul' }
  it { should be_grouped_into 'consul' }
  it { should be_mode 760 }
end

if agent_settings['ssl']['enabled'] 
  describe file(agent_settings['ssl']['dir']) do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'consul' }
    it { should be_grouped_into 'consul' }
    it { should be_mode 760 }
  end

  if agent_settings['ssl']['ca']['name']
    ca_file = File.join(agent_settings['ssl']['dir'], agent_settings['ssl']['ca']['name'])
  elsif agent_settings['ssl']['ca']['source']
    ca_file = File.join(agent_settings['ssl']['dir'], File.basename(agent_settings['ssl']['ca']['source']))
  else
    ca_file = nil
  end
    
  if ca_file
    describe file(ca_file) do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'consul' }
      it { should be_grouped_into 'consul' }
      it { should be_mode 660 }
    end
  end  


  if agent_settings['ssl']['cert']['name']
    cert_file = File.join(agent_settings['ssl']['dir'], agent_settings['ssl']['cert']['name'])
  elsif agent_settings['ssl']['cert']['source']
    cert_file = File.join(agent_settings['ssl']['dir'], File.basename(agent_settings['ssl']['cert']['source']))
  else
    cert_file = nil
  end
    
  if cert_file
    describe file(cert_file) do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'consul' }
      it { should be_grouped_into 'consul' }
      it { should be_mode 660 }
    end
  end


  if agent_settings['ssl']['key']['name']
    key_file = File.join(agent_settings['ssl']['dir'], agent_settings['ssl']['key']['name'])
  elsif agent_settings['ssl']['key']['source']
    key_file = File.join(agent_settings['ssl']['dir'], File.basename(agent_settings['ssl']['key']['source']))
  else
    key_file = nil
  end
    
  if key_file
    describe file(key_file) do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'consul' }
      it { should be_grouped_into 'consul' }
      it { should be_mode 660 }
    end
  end  
end


describe file(agent_settings['data_dir']) do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'consul' }
  it { should be_grouped_into 'consul' }
  it { should be_mode 760 }
end


describe file(agent_settings['scripts_dir']) do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by 'consul' }
  it { should be_grouped_into 'consul' }
  it { should be_mode 770 }
end

if agent_settings['log'] and agent_settings['log_dir'] 
  describe file(agent_settings['log_dir']) do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'consul' }
    it { should be_grouped_into 'consul' }
  end

  describe file(File.join(agent_settings['log_dir'], 'agent.log')) do
    it { should exist }
    it { should be_file }
  end
end

# cosul.agent.config

agent_settings['scripts'].each do | script |

  if script.has_key?('name')
    script_name = script['name']
  else
    script_name = File.basename(script['source'].sub('salt://','/'))
  end

  describe file(File.join(agent_settings['scripts_dir'], script_name)) do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'consul' }
    it { should be_grouped_into 'consul' }
    it { should be_mode 770 }
  end
end

describe file(File.join(agent_settings['opts']['config-dir'][0], 'config.json')) do
  it { should exist }
  it { should be_file }
  it { should be_owned_by 'consul' }
  it { should be_grouped_into 'consul' }
end

describe 'consul agent config file' do
  it 'should match merged pillar data when rendered to json' do
    config_file = File.read(File.join(agent_settings['opts']['config-dir'][0], 'config.json'))
    expect(agent_settings['config'].to_json).to be_json_eql(config_file)
  end
end

if agent_settings['services']
  describe file(File.join(agent_settings['opts']['config-dir'][0], 'services.json')) do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'consul' }
    it { should be_grouped_into 'consul' }
  end

  describe 'consul agent services file' do
    it 'should match merged pillar data when rendered to json' do
      service_file = File.read(File.join(agent_settings['opts']['config-dir'][0], 'services.json'))
      service_hash = JSON.parse(service_file)
      expect(service_hash['services'].to_json).to be_json_eql(agent_settings['services'].to_json)
    end
  end
end


if agent_settings['checks']
  describe file(File.join(agent_settings['opts']['config-dir'][0], 'checks.json')) do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'consul' }
    it { should be_grouped_into 'consul' }
  end

  describe 'consul agent checks file' do
    it 'should match merged pillar data when rendered to json' do
      check_file = File.read(File.join(agent_settings['opts']['config-dir'][0], 'checks.json'))
      check_hash = JSON.parse(check_file)
      expect(check_hash['checks'].to_json).to be_json_eql(agent_settings['checks'].to_json)
    end
  end
end


# consul.agent.service
if agent_settings['pkg']['service']
  describe file(agent_settings['service_def']['name']) do
    it { should exist }
    it { should be_file }
  end

  describe service('consul') do
    it { should be_enabled }
    it { should be_running }
  end

  describe command('ps aux | grep "consul agent"') do
    agent_settings['opts'].each do | k,v |
      if not v.nil?
        v.each do | opt |
          its(:stdout) { should contain '-' + k + '=' + opt }
        end
      else
        its(:stdout) { should contain '-' + k }
      end
    end
  end
end
