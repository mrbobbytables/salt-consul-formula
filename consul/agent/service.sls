{% from 'consul/map.jinja' import agent_settings with context %}

{% if agent_settings.service_def is defined and agent_settings.pkg.service == true %}

{% if salt['test.provider']('service') == 'systemd' %}

consul-agent-systemd-unit-helper:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: configure-consul-agent-service

{% endif %}

configure-consul-agent-service:
  file.managed:
    - name: {{ agent_settings.service_def.name }}
    - source: {{ agent_settings.service_def.source }}
    - mode: {{ agent_settings.service_def.mode }}
    - template: jinja


consul-agent-service:
  service.running:
    - name: consul
    - enable: true
    - watch:
      - file: {{ agent_settings.opts['config-dir'][0] }}/*
      - file: configure-consul-agent-service

{% endif %}
