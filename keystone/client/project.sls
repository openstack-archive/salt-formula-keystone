{%- from "keystone/map.jinja" import client with context %}
{%- if client.enabled %}

{%- if client.tenant is defined %}

keystone_salt_config:
  file.managed:
    - name: /etc/salt/minion.d/keystone.conf
    - template: jinja
    - source: salt://keystone/files/salt-minion.conf
    - mode: 600

keystone_client_roles:
  keystone.role_present:
  - names: {{ client.roles }}
  - connection_user: {{ client.server.user }}
  - connection_password: {{ client.server.password }}
  - connection_tenant: {{ client.server.tenant }}
  - connection_auth_url: 'http://{{ client.server.host }}:{{ client.server.public_port }}/v2.0/'
  - require:
    - file: keystone_salt_config

{%- for tenant_name, tenant in client.get('tenant', {}).iteritems() %}

keystone_tenant_{{ tenant_name }}:
  keystone.tenant_present:
  - name: {{ tenant_name }}
  - connection_user: {{ client.server.user }}
  - connection_password: {{ client.server.password }}
  - connection_tenant: {{ client.server.tenant }}
  - connection_auth_url: 'http://{{ client.server.host }}:{{ client.server.public_port }}/v2.0/'
  - require:
    - keystone: keystone_client_roles

{%- for user_name, user in tenant.get('user', {}).iteritems() %}

keystone_{{ tenant_name }}_user_{{ user_name }}:
  keystone.user_present:
  - name: {{ user_name }}
  - password: {{ user.password }}
  - email: {{ user.get('email', 'root@localhost') }}
  - tenant: {{ tenant_name }}
  - roles:
      "{{ tenant_name }}":
        {%- if user.get('is_admin', False) %}
        - admin
        {%- elif user.get('roles', False) %}
        {{ user.roles }}
        {%- else %}
        - Member
        {%- endif %}
  - connection_user: {{ client.server.user }}
  - connection_password: {{ client.server.password }}
  - connection_tenant: {{ client.server.tenant }}
  - connection_auth_url: 'http://{{ client.server.host }}:{{ client.server.public_port }}/v2.0/'
  - require:
    - keystone: keystone_tenant_{{ tenant_name }}

{%- endfor %}

{%- endfor %}

{%- endif %}

{%- endif %}
