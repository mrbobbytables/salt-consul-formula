{% from 'consul/map.jinja' import agent_settings with context %}

include:
  - consul.prereqs

create-consul-agent-config-directoiry:
  file.directory:
    - name: {{ agent_settings.opts['config-dir'][0] }}
    - user: consul
    - group: consul
    - mode: '0760'
    - makedirs: true


{% if agent_settings.ssl.enabled %}
create-consul-agent-ssl-directory:
  file.directory:
  - name: {{ agent_settings.ssl.dir }}
  - user: consul
  - group: consul
  - mode: '0760'
  - makedirs: true


{% if agent_settings.ssl.ca.source is not none %}
sync-consul-agent-ssl-ca:
  file.managed:
  - name: {{ agent_settings.ssl.dir }}/{{ agent_settings.ssl.ca.name }}
  - source: {{ agent_settings.ssl.ca.source }}
  - user: consul
  - group: consul
  - mode: '0660'
  - makedirs: true
{% endif %}


{% if agent_settings.ssl.cert.source is not none %}
sync-consul-agent-ssl-cert:
  file.managed:
  - name: {{ agent_settings.ssl.dir }}/{{ agent_settings.ssl.cert.name }}
  - source: {{ agent_settings.ssl.cert.source }}
  - user: consul
  - group: consul
  - mode: '0660'
  - makedirs: true
{% endif %}


{% if agent_settings.ssl.key.source is not none %}
sync-consul-agent-ssl-key:
  file.managed:
  - name: {{ agent_settings.ssl.dir }}/{{ agent_settings.ssl.key.name }}
  - source: {{ agent_settings.ssl.key.source }}
  - user: consul
  - group: consul
  - mode: '0660'
  - makedirs: true
{% endif %}
{% endif %}


create-consul-agent-data-directory:
  file.directory:
    - name: {{ agent_settings.data_dir }}
    - user: consul
    - group: consul
    - mode: '0760'
    - makedirs: true


create-consul-scripts-directory:
  file.directory:
    - name: {{ agent_settings.scripts_dir }}
    - user: consul
    - group: consul
    - mode: '0770'
    - makedirs: true


{% if agent_settings.log %}
create-consul-agent-log-directory:
  file.directory:
    - name: {{ agent_settings.log_dir }}
    - user: consul
    - group: consul
    - makedirs: true
{% endif %}


download-consul-agent:
  file.managed:
    - name: /tmp/{{ agent_settings.pkg.agent_name }}
    - source: {{ agent_settings.pkg.uri }}
    - source_hash: {{ agent_settings.pkg.hash }}
    - require:
      - sls: consul.prereqs
    - unless:
      - test -f /usr/local/bin/consul-{{ agent_settings.pkg.version }}


extract-consul-agent:
  cmd.wait:
    - name: unzip -q -o /tmp/{{ agent_settings.pkg.agent_name }}
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
    - name: /tmp/{{ salt['file.basename'](agent_settings.pkg.agent_name) }}
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
