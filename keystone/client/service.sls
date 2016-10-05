{%- from "keystone/map.jinja" import client with context %}
{%- if client.enabled %}

keystone_client_packages:
  pkg.installed:
  - names: {{ client.pkgs }}

{%- endif %}
