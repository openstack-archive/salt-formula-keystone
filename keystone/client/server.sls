{%- from "keystone/map.jinja" import client with context %}
{%- if client.enabled %}

{%- for server_name, server in client.get('server', {}).iteritems() %}

{%- if server.admin.get('api_version', '2') == '3' %}
{%- set version = "v3" %}
{%- else %}
{%- set version = "v2.0" %}
{%- endif %}

{%- if server.admin.get('protocol', 'http') == 'http' %}
{%- set protocol = 'http' %}
{%- else %}
{%- set protocol = 'https' %}
{%- endif %}


{%- if server.admin.token is defined %}
{%- set connection_args = {'endpoint': protocol+'://'+server.admin.host+':'+server.admin.port|string+'/'+version,
                           'token': server.admin.token} %}
{%- else %}
{%- set connection_args = {'auth_url': protocol+'://'+server.admin.host+':'+server.admin.port|string+'/'+version,
                           'tenant': server.admin.project,
                           'user': server.admin.user,
                           'password': server.admin.password} %}
{%- endif %}

{%- if server.roles is defined %}

keystone_{{ server_name }}_roles:
  keystone.role_present:
  - names: {{ server.roles }}
  {%- if server.admin.token is defined %}
  - connection_token: {{ connection_args.token }}
  - connection_endpoint: {{ connection_args.endpoint }}
  {%- else %}
  - connection_user: {{ connection_args.user }}
  - connection_password: {{ connection_args.password }}
  - connection_tenant: {{ connection_args.tenant }}
  - connection_auth_url: {{ connection_args.auth_url }}
  {%- endif %}

{%- endif %}

{% for service_name, service in server.get('service', {}).iteritems() %}

keystone_{{ server_name }}_service_{{ service_name }}:
  keystone.service_present:
  - name: {{ service_name }}
  - service_type: {{ service.type }}
  - description: {{ service.description }}
  {%- if server.admin.token is defined %}
  - connection_token: {{ connection_args.token }}
  - connection_endpoint: {{ connection_args.endpoint }}
  {%- else %}
  - connection_user: {{ connection_args.user }}
  - connection_password: {{ connection_args.password }}
  - connection_tenant: {{ connection_args.tenant }}
  - connection_auth_url: {{ connection_args.auth_url }}
  {%- endif %}

{%- for endpoint in service.get('endpoints', ()) %}

keystone_{{ server_name }}_service_{{ service_name }}_endpoint_{{ endpoint.region }}:
  keystone.endpoint_present:
  - name: {{ service_name }}
  - publicurl: '{{ endpoint.get('public_protocol', 'http') }}://{{ endpoint.public_address }}:{{ endpoint.public_port }}{{ endpoint.public_path }}'
  - internalurl: '{{ endpoint.get('internal_protocol', 'http') }}://{{ endpoint.internal_address }}:{{ endpoint.internal_port }}{{ endpoint.internal_path }}'
  - adminurl: '{{ endpoint.get('admin_protocol', 'http') }}://{{ endpoint.admin_address }}:{{ endpoint.admin_port }}{{ endpoint.admin_path }}'
  - region: {{ endpoint.region }}
  - require:
    - keystone: keystone_{{ server_name }}_service_{{ service_name }}
  {%- if server.admin.token is defined %}
  - connection_token: {{ connection_args.token }}
  - connection_endpoint: {{ connection_args.endpoint }}
  {%- else %}
  - connection_user: {{ connection_args.user }}
  - connection_password: {{ connection_args.password }}
  - connection_tenant: {{ connection_args.tenant }}
  - connection_auth_url: {{ connection_args.auth_url }}
  {%- endif %}

{%- endfor %}

{%- endfor %}

{%- for tenant_name, tenant in server.get('project', {}).iteritems() %}

keystone_{{ server_name }}_tenant_{{ tenant_name }}:
  keystone.tenant_present:
  - name: {{ tenant_name }}
  {%- if tenant.description is defined %}
  - description: {{ tenant.description }}
  {%- endif %}
  {%- if server.admin.token is defined %}
  - connection_token: {{ connection_args.token }}
  - connection_endpoint: {{ connection_args.endpoint }}
  {%- else %}
  - connection_user: {{ connection_args.user }}
  - connection_password: {{ connection_args.password }}
  - connection_tenant: {{ connection_args.tenant }}
  - connection_auth_url: {{ connection_args.auth_url }}
  {%- endif %}

{%- for user_name, user in tenant.get('user', {}).iteritems() %}

keystone_{{ server_name }}_tenant_{{ tenant_name }}_user_{{ user_name }}:
  keystone.user_present:
  - name: {{ user_name }}
  - password: {{ user.password }}
  {%- if user.email is defined %}
  - email: {{ user.email }}
  {%- endif %}
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
    - keystone: keystone_{{ server_name }}_tenant_{{ tenant_name }}
    - keystone: keystone_{{ server_name }}_roles
  {%- if server.admin.token is defined %}
  - connection_token: {{ connection_args.token }}
  - connection_endpoint: {{ connection_args.endpoint }}
  {%- else %}
  - connection_user: {{ connection_args.user }}
  - connection_password: {{ connection_args.password }}
  - connection_tenant: {{ connection_args.tenant }}
  - connection_auth_url: {{ connection_args.auth_url }}
  {%- endif %}

{%- endfor %}

{%- endfor %}

{%- endfor %}

{%- endif %}
