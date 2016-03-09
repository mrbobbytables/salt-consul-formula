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
salt_provider = %x(salt-call --local --config=/tmp/kitchen/etc/salt test.provider service)
salt_osarch = %x(salt-call --local --config=/tmp/kitchen/etc/salt grains.get osarch)
salt_kernel = %x(salt-call --local --config=/tmp/kitchen/etc/salt grains.get kernel)
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


template_settings = {}
template_settings.deep_merge(defaults['template'])
template_settings.deep_merge(pillar_data['consul']['lookup']['template'])


case salt_osarch[/^local:\s+(?<osarch>\S+)\z/, :osarch]
when 'amd64', 'x86_64'
  osarch = 'amd64'
else
  osarch = salt_osarch[/local:\s+(?<osarch>\S+)/, :osarch].downcase
end

if template_settings['config']['data_dir']
  template_settings['data_dir'] = template_settings['config']['data_dir']
end

if template_settings['opts']['data-dir']
  template_settings['data_dir'] = template_settings['opts']['data-dir'][0]
end

pkg_path = '/tmp/consul_' + template_settings['pkg']['version'] + '_' + kernel + '_' + osarch + '.zip'


# consul.prereqs

describe 'SLS: consul.prereqs' do
  describe 'STATE: create-consul-user' do
    describe user('consul') do
      it { should exist }
    end
  end

  describe 'STATE: create-consul-group' do
    describe group('consul') do
      it { should exist }
    end
  end
end


# consul.template.install

describe 'SLS: consul.template.install' do

  describe 'STATE: create-consul-template-config-directory' do
    describe file(template_settings['opts']['config'][0]) do
      it { should exist }
      it { should be_directory }
      it { should be_owned_by 'consul' }
      it { should be_grouped_into 'consul' }
      it { should be_mode 760 }
    end
  end

  describe 'STATE: create-consul-template-templates-directory' do
    describe file(template_settings['templates_dir']) do
      it { should exist }
      it { should be_directory }
      it { should be_owned_by 'consul' }
      it { should be_grouped_into 'consul' }
      it { should be_mode 660 }
    end
  end


  if template_settings['log'] and template_settings['log_dir'] 
    describe 'STATE: create-consul-template-log-directory' do
      describe file(template_settings['log_dir']) do
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'consul' }
        it { should be_grouped_into 'consul' }
      end
    end

    describe 'ARTIFACT: provider specific logging' do
      describe file(File.join(template_settings['log_dir'], 'template.log')) do
        it { should exist }
        it { should be_file }
      end
    end
  end


  if template_settings['ssl']['enabled'] 
    describe 'STATE: create-consul-ssl-directory' do
      describe file(template_settings['ssl']['dir']) do
        it { should exist }
        it { should be_directory }
        it { should be_owned_by 'consul' }
        it { should be_grouped_into 'consul' }
        it { should be_mode 760 }
      end
    end


    if template_settings['ssl']['ca']['name']
      ca_file = File.join(template_settings['ssl']['dir'], template_settings['ssl']['ca']['name'])
    elsif template_settings['ssl']['ca']['source']
      ca_file = File.join(template_settings['ssl']['dir'], File.basename(template_settings['ssl']['ca']['source']))
    else
      ca_file = nil
    end
  

    if ca_file
      describe 'STATE: sync-consul-template-ssl-ca' do
        describe file(ca_file) do
          it { should exist }
          it { should be_file }
          it { should be_owned_by 'consul' }
          it { should be_grouped_into 'consul' }
          it { should be_mode 660 }
        end
      end  
    end


    if template_settings['ssl']['cert']['name']
      cert_file = File.join(template_settings['ssl']['dir'], template_settings['ssl']['cert']['name'])
    elsif template_settings['ssl']['cert']['source']
      cert_file = File.join(template_settings['ssl']['dir'], File.basename(template_settings['ssl']['cert']['source']))
    else
      cert_file = nil
    end


    if cert_file
      describe 'STATE: sync-consul-template-cert' do
        describe file(cert_file) do
          it { should exist }
          it { should be_file }
          it { should be_owned_by 'consul' }
          it { should be_grouped_into 'consul' }
          it { should be_mode 660 }
        end
      end
    end


    if template_settings['ssl']['key']['name']
      key_file = File.join(template_settings['ssl']['dir'], template_settings['ssl']['key']['name'])
    elsif template_settings['ssl']['key']['source']
      key_file = File.join(template_settings['ssl']['dir'], File.basename(template_settings['ssl']['key']['source']))
    else
      key_file = nil
    end


    if key_file
      describe 'STATE: sync-consul-template-key' do
        describe file(key_file) do
          it { should exist }
          it { should be_file }
          it { should be_owned_by 'consul' }
          it { should be_grouped_into 'consul' }
          it { should be_mode 660 }
        end
      end  
    end
  end

  describe 'STATE: move-consul-template-binary' do
    describe file('/usr/local/bin/consul-template-' + template_settings['pkg']['version']) do
      it { should exist }
      it { should be_file }
      it { should be_executable }
    end
  end


  describe 'STATE: symlink-consul-binary' do
    describe file('/usr/local/bin/consul-template') do
      it { should exist }
      it { should be_symlink }
      it { should be_executable }
    end
  end


  describe 'STATE: clean-consul-template-archive' do
    describe file(pkg_path) do
      it { should_not exist }
    end
  end

end



# cosul.template.config

describe 'SLS: consul.template.config' do

  describe 'STATE: sync-consul-template-*' do
    template_settings['templates'].each do | template |

      if template.has_key?('name')
        template_name = template['name']
      else
        template_name = File.basename(template['source'].sub('salt://','/'))
      end

      describe file(File.join(template_settings['templates_dir'], template_name)) do
        it { should exist }
        it { should be_file }
        it { should be_owned_by 'consul' }
        it { should be_grouped_into 'consul' }
        it { should be_mode 660 }
      end
    end
  end

  describe 'STATE: config-consul-template' do
    describe file(File.join(template_settings['opts']['config'][0], 'config.json')) do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'consul' }
      it { should be_grouped_into 'consul' }
    end

    describe 'RENDER: config-consul-template' do
      it 'should match merged pillar data when rendered to json' do
        config_file = File.read(File.join(template_settings['opts']['config'][0], 'config.json'))
        expect(template_settings['config'].to_json).to be_json_eql(config_file)
      end
    end
  end

  describe 'STATE: config-consul-template-templates' do
    describe file(File.join(template_settings['opts']['config'][0], 'templates.hcl')) do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'consul' }
      it { should be_grouped_into 'consul' }
    end

    describe 'TEMPLATE: /consul/template/templates.jinja' do
      describe file(File.join(template_settings['opts']['config'][0], 'templates.hcl')) do
        template_settings['templates'].each do | tmplt |
          tmplt['config'].each do | k,v |
            if k != 'perms'
              its(:content) { should contain "\"#{k}\" = \"#{v}" }
            else
              its(:content) { should contain "\"#{k}\" = #{v}" }
            end
          end
        end
      end
    end
  end
end



# consul.template.service

if template_settings['pkg']['service']
  describe 'SLS: consul.template.service' do

    describe 'STATE: config-consul-template-service' do
      describe file(template_settings['service_def']['name']) do
        it { should exist }
        it { should be_file }
      end

      describe 'RENDER: config-consul-template-service' do
        describe command('ps aux | grep "consul-template"') do
          template_settings['opts'].each do | k,v |
            if not v.nil?
              v.each do | opt |
                its(:stdout) { should contain "-#{k}=#{opt}" }
              end
            else
              its(:stdout) { should contain "-#{k}" }
            end
          end
        end
      end
    end

   describe 'STATE: consul-template-service' do
     describe service('consul-template') do
       it { should be_enabled }
       it { should be_running }
     end
   end
  end
end

describe 'CONSUL-TEMPLATE: Render tests' do
  describe file('/tmp/ct_cmd_test_1') do
    it { should exist }
    it { should be_file }
  end

  describe file('/tmp/ct_render_test_1') do
    it { should exist }
    it { should be_file }
    its(:content) { should contain 'data1' }
  end


  describe file('/tmp/ct_cmd_test_2') do
    it { should exist }
    it { should be_file }
  end

  describe file('/tmp/ct_render_test_2') do
    it { should exist }
    it { should be_file }
    it { should be_mode 777 }
    its(:content) { should contain 'data2' }
  end
end
