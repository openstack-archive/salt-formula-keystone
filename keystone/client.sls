{%- from "keystone/map.jinja" import client with context %}
{%- if client.enabled %}

keystone_client_packages:
  pkg.installed:
  - names: {{ client.pkgs }}

keystone_salt_config:
  file.managed:
    - name: /etc/salt/minion.d/keystone.conf
    - template: jinja
    - source: salt://keystone/files/salt-minion.conf
    - mode: 600

{%- if client.tenant is defined %}

keystone_client_roles:
  keystone.role_present:
  - names: {{ client.roles }}
  - require:
    - file: keystone_salt_config

{%- for tenant_name, tenant in client.get('tenant', {}).iteritems() %}

keystone_tenant_{{ tenant_name }}:
  keystone.tenant_present:
  - name: {{ tenant_name }}
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
  - require:
    - keystone: keystone_tenant_{{ tenant_name }}

{%- endfor %}

{%- endfor %}

{%- endif %}

{%- endif %}
