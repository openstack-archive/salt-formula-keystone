{%- from "keystone/map.jinja" import control with context %}
{%- for provider_name, provider in control.get('provider', {}).iteritems() %}

/root/keystonerc_{{ provider_name }}:
  file.managed:
  - source: salt://keystone/files/keystonerc_user
  - template: jinja
  - defaults:
      provider_name: "{{ provider_name }}"

{%- endfor %}
