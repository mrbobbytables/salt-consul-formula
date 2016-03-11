{% from 'consul/map.jinja' import agent_settings with context %}
{% from 'consul/map.jinja' import template_settings with context %}

include:
- consul.prereqs
{% if agent_settings.pkg.install == true %}
 - consul.agent
{% endif %}
{% if template_settings.pkg.install == true %}
- consul.template
{% endif %}
