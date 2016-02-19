{% from 'consul/map.jinja' import agent_settings %}
{% if salt['grains.get']('osarch') == 'amd64' or salt['grains.get']('osarch') == 'x86_64' %}
{% set osarch = 'amd64' %}
{% else %}
{% set osarch = salt['grains.get']('osarch') %}
{% endif %}

{% set agent_pkg_name = 'consul_' ~ agent_settings.pkg.version ~ '_' ~ salt['grains.get']('kernel')|lower ~ '_' ~ osarch  ~ '.zip' %}
{% set ui_pkg_name = 'consul_' ~ agent_settings.pkg.version ~ '_web_ui.zip' %}


include:
  - consul.prereqs

create-consul-agent-config-directoiry:
  file.directory:
    - name: {{ agent_settings.opts['config-dir'][0] }}
    - user: consul
    - group: consul
    - makedirs: true

create-consul-agent-ssl-directory:
  file.directory:
  - name: {{ salt['file.dirname'](agent_settings.opts['config-dir'][0]) }}/ssl
  - user: consul
  - group: consul
  - mode: '0700'
  - makedirs: true


create-consul-agent-data-directory:
  file.directory:
    - name: {{ agent_settings.data_dir }}
    - user: consul
    - group: consul
    - makedirs: true

create-consul-ui-directory:
  file.directory:
    - name: {{ salt['file.dirname'](agent_settings.ui_dir) }}
    - user: consul
    - group: consul
    - makedirs: true

{% if agent_settings.log == true %}
create-consul-log-directory:
  file.directory:
    - name: {{ agent_settings.log_dir }}
    - user: consul
    - group: consul
    - makedirs: true
{% endif %}

download-consul-agent:
  file.managed:
    - name: /tmp/{{ agent_pkg_name }}
    - source: https://releases.hashicorp.com/consul/{{ agent_settings.pkg.version }}/{{ agent_pkg_name }}
    - source_hash: https://releases.hashicorp.com/consul/{{ agent_settings.pkg.version}}/consul_{{ agent_settings.pkg.version }}_SHA256SUMS
    - require:
      - sls: consul.prereqs
    - unless:
      - test -f /usr/local/bin/consul-{{ agent_settings.pkg.version }}

extract-consul-agent:
  cmd.wait:
    - name: unzip -q -o /tmp/{{ agent_pkg_name }}
    - cwd: /tmp/
    - watch:
      - file: download-consul-agent

move-consul-agent-binary:
   file.rename:
     - name: /usr/local/bin/consul-{{ agent_settings.pkg.version }}
     - source: /tmp/consul
     - watch:
       - cmd: extract-consul-agent

clean-consul-archive:
  file.absent:
    - name: /tmp/{{ agent_pkg_name }}
    - watch:
       - file: move-consul-agent-binary

clean-consul-extracted-binary:
  file.absent:
    - name: /tmp/consul-{{ agent_settings.pkg.version }}
    - watch:
      - file: move-consul-agent-binary


symlink-consul-agent-binary:
  file.symlink:
    - name: /usr/local/bin/consul
    - target: /usr/local/bin/consul-{{ agent_settings.pkg.version }}
    - onlyif:
      - test -f /usr/local/bin/consul-{{ agent_settings.pkg.version }}
    - unless:
      - /usr/local/bin/consul --version | grep -q {{ agent_settings.pkg.version }}


download-consul-ui:
  file.managed:
    - name: /tmp/{{ ui_pkg_name }}
    - source: https://releases.hashicorp.com/consul/{{ agent_settings.pkg.version }}/{{ ui_pkg_name }}
    - source_hash: https://releases.hashicorp.com/consul/{{ agent_settings.pkg.version}}/consul_{{ agent_settings.pkg.version }}_SHA256SUMS
    - unless:
      - test -d {{ agent_settings.ui_dir }}-{{ agent_settings.pkg.version }}
    - require:
      - sls: consul.prereqs

extract-consul-ui:
  cmd.wait:
    - name: unzip -q -o /tmp/{{ ui_pkg_name }}
    - cwd: /tmp/
    - watch:
      - file: download-consul-ui

move-consul-ui:
   file.rename:
     - name: {{ agent_settings.ui_dir }}-{{ agent_settings.pkg.version }}
     - source: /tmp/consul-ui-{{ agent_settings.pkg.version }}
     - watch:
       - cmd: extract-consul-ui

modify-consul-ui-dir-permissions:
  file.directory:
    - name: {{ agent_settings.ui_dir }}-{{agent_settings.pkg.version }}
    - user: consul
    - group: consul
    - watch:
      - file: move-consul-ui

clean-consul-ui-archive:
  file.absent:
    - name: /tmp/{{ ui_pkg_name }}
    - watch:
       - file: symlink-consul-ui


symlink-consul-ui:
  file.symlink:
    - name: {{ agent_settings.ui_dir }}
    - target: {{ agent_settings.ui_dir }}-{{ agent_settings.pkg.version }}
    - user: consul
    - group: consul
    - makedirs: true
    - onlyif:
       - test -d {{ agent_settings.ui_dir }}-{{ agent_settings.pkg.version }}
    - unless:
       - readlink {{ agent_settings.ui_dir }} | grep -q {{ agent_settings.pkg.version }}

