{% from 'consul/map.jinja' import agent_settings with context %}
{% from 'consul/map.jinja' import envconsul_settings with context %}
{% from 'consul/map.jinja' import template_settings with context %}
{% from 'consul/map.jinja' import replicate_settings with context %}

include:
- consul.prereqs
{% if agent_settings.pkg.install == true %}
 - consul.agent
{% endif %}
{% if replicate_settings.pkg.install == true %}
- consul.replicate
{% endif %}
{% if template_settings.pkg.install == true %}
- consul.template
{% endif %}
{% if envconsul_settings.pkg.install == true %}
- consul.envconsul
{% endif %}
