{% from 'consul/map.jinja' import template_settings with context %}
{% set template_list = [] %}

include:
  - consul.prereqs

{% for tmplt in template_settings.templates %}
sync-consul-template-{{ template_settings.templates_dir ~ '/' ~ tmplt.name }}:
  file.managed:
    - name: {{ template_settings.templates_dir ~ '/' ~ tmplt.name }}
    - source: {{ tmplt.source }}
    - user: consul
    - group: consul
    - require:
      - sls: consul.prereqs
{% if 'template' in tmplt %}
    - template: {{ tmplt.template }}
{% endif %}
{% do template_list.append(tmplt.config) %}
{% endfor %}


config-consul-template:
  file.managed:
    - name: {{ template_settings.opts['config'][0] }}/config.json
    - source: salt://consul/template/templates/config.jinja
    - template: jinja
    - user: consul
    - group: consul
    - require:
       - sls: consul.prereqs

{% if template_settings.templates %}
config-consul-template-templates:
  file.managed:
    - name: {{ template_settings.opts['config'][0] }}/templates.json
    - source: salt://consul/template/templates/templates.jinja
    - template: jinja
    - user: consul
    - group: consul
    - defaults:
        template_list: {{ template_list }}
    - require:
       - sls: consul.prereqs
{% endif %}


{% if salt['service.available']('consul-template') %}

{% if salt['test.provider']('service') == 'systemd' %}

consul-template-config-systemd-unit-helper:
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: config-consul-template
{% if template_settings.templates %}      
      - file: config-consul-template-temaplates
{% endif %}
{% endif %}

consul-template-config-service-reloader:
  service.running:
  - name: consul-template
  - enable: true
  - watch:
    - file: config-consul-template
{% if template_settings.templates %}
    - file: config-consul-template-templates
{% endif %}
{% endif %}


