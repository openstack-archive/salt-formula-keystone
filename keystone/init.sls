{%- from "keystone/map.jinja" import server with context %}

include:
{% if pillar.keystone.server is defined %}
- keystone.server
{% if server.service_name in ['apache2', 'httpd'] %}
- apache
{% endif %}
{% endif %}
{% if pillar.keystone.client is defined %}
- keystone.client
{% endif %}
{% if pillar.keystone.control is defined %}
- keystone.control
{% endif %}
