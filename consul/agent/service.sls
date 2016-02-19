{% from 'consul/map.jinja' import agent_settings with context %}
{% set service_type = salt['test.provider']('service') %}
{% if service_type  == 'upstart' %}
  {% set service_def = {
    'name': '/etc/init/consul.conf',
    'source': 'salt://consul/agent/templates/upstart.jinja',
    'mode': '0644'
    }
  %}
{% elif service_type == 'debian_service' %}
  {% set service_def = {
    'name': '/etc/init.d/consul',
    'source': 'salt://consul/agent/templates/debian_service.jinja',
    'mode': '0755' 
    }
  %}
{% elif service_type == 'sysvinit' %}
  {% set service_def = {
    'name': '/etc/init.d/consul',
    'source': 'salt://consul/agent/templates/sysvinit.jinja',
    'mode': '0755' 
    }
  %}
{% elif service_type == 'systemd' %}
  {% set service_def = {
    'name': '/etc/systemd/system/consul.service',
    'source': 'salt://consul/agent/templates/systemd.jinja',
    'mode': '0644'
    }
  %}

consul-agent-systemd-unit-helper:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: configure-consul-agent-service
{% endif %}

{% if service_def is defined and agent_settings.pkg.service == true %}
configure-consul-agent-service:
  file.managed:
    - name: {{ service_def.name }}
    - source: {{ service_def.source }}
    - mode: {{ service_def.mode }}
    - template: jinja

consul-agent-service:
  service.running:
    - name: consul
    - enable: true
    - watch:
      - file: {{ agent_settings.opts['config-dir'][0] }}/*
      - file: configure-consul-agent-service
{% endif %}

