{% from 'consul/map.jinja' import template_settings with context %}

include:
  - consul.prereqs


create-consul-template-config-directory:
  file.directory:
    - name: {{ template_settings.opts['config'][0] }}
    - user: consul
    - group: consul
    - makedirs: true

create-consul-template-ssl-directory:
  file.directory:
  - name: {{ salt['file.dirname'](template_settings.opts['config'][0]) }}/ssl
  - user: consul
  - group: consul
  - mode: '0700'
  - makedirs: true


create-consul-template-templates-directory:
  file.directory:
    - name: {{ template_settings.templates_dir }}
    - user: consul
    - group: consul
    - makedirs: true

{% if template_settings.log == true %}
create-consul-template-log-directory:
  file.directory:
    - name: {{ template_settings.log_dir }}
    - user: consul
    - group: consul
    - makedirs: true
{% endif %}

download-consul-template:
  file.managed:
    - name: /tmp/{{ template_settings.pkg.template_name }}
    - source: {{ template_settings.pkg.template_uri }}
    - source_hash: {{ template_settings.pkg.template_hash }}
    - require:
      - sls: consul.prereqs
    - unless:
      - test -f /usr/local/bin/consul-template-{{ template_settings.pkg.version }}

extract-consul-template:
  cmd.wait:
    - name: unzip -q -o /tmp/{{ template_settings.pkg.template_name }}
    - cwd: /tmp/
    - watch:
      - file: download-consul-template

move-consul-template-binary:
   file.rename:
     - name: /usr/local/bin/consul-template-{{ template_settings.pkg.version }}
     - source: /tmp/consul-template
     - watch:
       - cmd: extract-consul-template

clean-consul-template-archive:
  file.absent:
    - name: /tmp/{{ template_settings.pkg.template_name }}
    - watch:
       - file: move-consul-template-binary

symlink-consul-template-binary:
  file.symlink:
    - name: /usr/local/bin/consul-template
    - target: /usr/local/bin/consul-template-{{ template_settings.pkg.version }}
    - onlyif:
      - test -f /usr/local/bin/consul-template-{{ template_settings.pkg.version }}
    - unless:
      - /usr/local/bin/consul-template --version | grep -q {{ template_settings.pkg.version }}

