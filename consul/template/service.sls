{% from 'consul/map.jinja' import template_settings with context %}

{% if template_settings.service_def is defined and template_settings.pkg.service == true %}

{% if salt['test.provider']('service') == 'systemd' %}

consul-template-systemd-unit-helper:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: configure-consul-template-service

{% endif %}

configure-consul-template-service:
  file.managed:
    - name: {{ template_settings.service_def.name }}
    - source: {{ template_settings.service_def.source }}
    - mode: {{ template_settings.service_def.mode }}
    - template: jinja


consul-template-service:
  service.running:
    - name: consul
    - enable: true
    - watch:
      - file: {{ template_settings.opts['config'][0] }}/*
      - file: configure-consul-template-service

{% endif %}
