
include:
{% if pillar.keystone.server is defined %}
- keystone.server
{% endif %}
{% if pillar.keystone.client is defined %}
- keystone.client
{% endif %}
{% if pillar.keystone.control is defined %}
- keystone.control
{% endif %}
