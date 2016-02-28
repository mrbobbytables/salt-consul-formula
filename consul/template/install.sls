{% from 'consul/map.jinja' import template_settings with context %}

include:
  - consul.prereqs


create-consul-template-config-directory:
  file.directory:
    - name: {{ template_settings.opts['config'][0] }}
    - user: consul
    - group: consul
    - mode: '0760'
    - makedirs: true


create-consul-template-templates-directory:
  file.directory:
    - name: {{ template_settings.templates_dir }}
    - user: consul
    - group: consul
    - mode: '0660'
    - makedirs: true


{% if template_settings.log %}
create-consul-template-log-directory:
  file.directory:
    - name: {{ template_settings.log_dir }}
    - user: consul
    - group: consul
    - makedirs: true
{% endif %}


{% if template_settings.ssl.enabled %}
create-consul-template-ssl-directory:
  file.directory:
  - name: {{ template_settings.ssl.dir }}
  - user: consul
  - group: consul
  - mode: '0760'
  - makedirs: true


{% if template_settings.ssl.ca.source is not none %}
sync-consul-template-ssl-ca:
  file.managed:
  - name: {{ template_settings.ssl.dir }}/{{ template_settings.ssl.ca.name }}
  - source: {{ template_settings.ssl.ca.source }}
  - user: consul
  - group: consul
  - mode: '0660'
  - makedirs: true
{% endif %}

{% if template_settings.ssl.cert.source is not none %}
sync-consul-template-ssl-cert:
  file.managed:
  - name: {{ template_settings.ssl.dir }}/{{ template_settings.ssl.cert.name }}
  - source: {{ template_settings.ssl.cert.source }}
  - user: consul
  - group: consul
  - mode: '0660'
  - makedirs: true
{% endif %}

{% if template_settings.ssl.key.source is not none %}
sync-consul-template-ssl-key:
  file.managed:
  - name: {{ template_settings.ssl.dir }}/{{ template_settings.ssl.key.name }}
  - source: {{ template_settings.ssl.key.source }}
  - user: consul
  - group: consul
  - mode: '0660'
  - makedirs: true
{% endif %}


{% endif %}



download-consul-template:
  file.managed:
    - name: /tmp/{{ template_settings.pkg.name }}
    - source: {{ template_settings.pkg.uri }}
    - source_hash: {{ template_settings.pkg.hash }}
    - require:
      - sls: consul.prereqs
    - unless:
      - test -f /usr/local/bin/consul-template-{{ template_settings.pkg.version }}

extract-consul-template:
  cmd.wait:
    - name: unzip -q -o /tmp/{{ template_settings.pkg.name }}
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
    - name: /tmp/{{ template_settings.pkg.name }}
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

