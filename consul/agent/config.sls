{% from 'consul/map.jinja' import agent_settings with context %}

config-consul-agent:
  file.managed:
    - name: {{ agent_settings.opts['config-dir'][0] }}/config.json
    - source: salt://consul/agent/templates/config.jinja
    - template: jinja
    - user: consul
    - group: consul
    - require:
       - sls: consul.prereqs


config-consul-agent-services:
  file.managed:
    - name: {{ agent_settings.opts['config-dir'][0] }}/services.json
    - source: salt://consul/agent/templates/services.jinja
    - template: jinja
    - user: consul
    - group: consul
    - require:
       - sls: consul.prereqs


config-consul-agent-checks:
  file.managed:
    - name: {{ agent_settings.opts['config-dir'][0] }}/checks.json
    - source: salt://consul/agent/templates/checks.jinja
    - template: jinja
    - user: consul
    - group: consul
    - require:
       - sls: consul.prereqs

