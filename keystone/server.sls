{%- from "keystone/map.jinja" import server with context %}
{%- if server.enabled %}

keystone_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

{%- if server.service_name in ['apache2', 'httpd'] %}
include:
- apache

{%- if grains.os_family == "Debian" %}
keystone:
{%- endif %}
{%- if grains.os_family == "RedHat" %}
openstack-keystone:
{%- endif %}
  service.dead:
    - enable: False
    - watch:
      - pkg: keystone_packages

{%- endif %}

keystone_salt_config:
  file.managed:
    - name: /etc/salt/minion.d/keystone.conf
    - template: jinja
    - source: salt://keystone/files/salt-minion.conf
    - mode: 600

{%- if not salt['user.info']('keystone') %}

keystone_user:
  user.present:
    - name: keystone
    - home: /var/lib/keystone
    - uid: 301
    - gid: 301
    - shell: /bin/false
    - system: True
    - require_in:
      - pkg: keystone_packages

keystone_group:
  group.present:
    - name: keystone
    - gid: 301
    - system: True
    - require_in:
      - pkg: keystone_packages
      - user: keystone_user

{%- endif %}

/etc/keystone/keystone.conf:
  file.managed:
  - source: salt://keystone/files/{{ server.version }}/keystone.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: keystone_packages
  - watch_in:
    - service: keystone_service

{% if server.websso is defined %}

/etc/keystone/sso_callback_template.html:
  file.managed:
  - source: salt://keystone/files/sso_callback_template.html
  - require:
    - pkg: keystone_packages
  - watch_in:
    - service: keystone_service

{%- endif %}

/etc/keystone/keystone-paste.ini:
  file.managed:
  - source: salt://keystone/files/{{ server.version }}/keystone-paste.ini.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: keystone_packages
  {%- if not grains.get('noservices', False) %}
  - watch_in:
    - service: keystone_service
  {%- endif %}

/etc/keystone/policy.json:
  file.managed:
  - source: salt://keystone/files/{{ server.version }}/policy-v{{ server.api_version }}.json
  - require:
    - pkg: keystone_packages
  {%- if not grains.get('noservices', False) %}
  - watch_in:
    - service: keystone_service
  {%- endif %}

{%- if server.get("domain", {}) %}

/etc/keystone/domains:
  file.directory:
    - mode: 0755
    - require:
      - pkg: keystone_packages

{%- for domain_name, domain in server.domain.iteritems() %}

/etc/keystone/domains/keystone.{{ domain_name }}.conf:
  file.managed:
    - source: salt://keystone/files/keystone.domain.conf
    - template: jinja
    - require:
      - file: /etc/keystone/domains
    {%- if not grains.get('noservices', False) %}
    - watch_in:
      - service: keystone_service
    {%- endif %}
    - defaults:
        domain_name: {{ domain_name }}

{%- if domain.get('ldap', {}).get('tls', {}).get('cacert', False) %}

keystone_domain_{{ domain_name }}_cacert:
  file.managed:
    - name: /etc/keystone/domains/{{ domain_name }}.pem
    - contents_pillar: keystone:server:domain:{{ domain_name }}:ldap:tls:cacert
    - require:
      - file: /etc/keystone/domains
    {%- if not grains.get('noservices', False) %}
    - watch_in:
      - service: keystone_service
    {%- endif %}

{%- endif %}

{%- if not grains.get('noservices', False) %}
keystone_domain_{{ domain_name }}:
  cmd.run:
    - name: source /root/keystonercv3 && openstack domain create --description "{{ domain.description }}" {{ domain_name }}
    - unless: source /root/keystonercv3 && openstack domain list | grep " {{ domain_name }}"
    - require:
      - file: /root/keystonercv3
      - service: keystone_service
{%- endif %}

{%- endfor %}

{%- endif %}

{%- if server.get('ldap', {}).get('tls', {}).get('cacert', False) %}

keystone_ldap_default_cacert:
  file.managed:
    - name: {{ server.ldap.tls.cacertfile }}
    - contents_pillar: keystone:server:ldap:tls:cacert
    - require:
      - pkg: keystone_packages
    {%- if not grains.get('noservices', False) %}
    - watch_in:
      - service: keystone_service
    {%- endif %}

{%- endif %}

{%- if not grains.get('noservices', False) %}
keystone_service:
  service.running:
  - name: {{ server.service_name }}
  - enable: True
  - watch:
    - file: /etc/keystone/keystone.conf
{%- endif %}

{%- if grains.get('virtual_subtype', None) == "Docker" %}
keystone_entrypoint:
  file.managed:
  - name: /entrypoint.sh
  - template: jinja
  - source: salt://keystone/files/entrypoint.sh
  - mode: 755
{%- endif %}

/root/keystonerc:
  file.managed:
  - source: salt://keystone/files/keystonerc
  - template: jinja
  - require:
    - pkg: keystone_packages

/root/keystonercv3:
  file.managed:
  - source: salt://keystone/files/keystonercv3
  - template: jinja
  - require:
    - pkg: keystone_packages

{%- if not grains.get('noservices', False) %}
keystone_syncdb:
  cmd.run:
  - name: keystone-manage db_sync; sleep 1
  - require:
    - service: keystone_service
{%- endif %}

{% if server.tokens.engine == 'fernet' %}

keystone_fernet_keys:
  file.directory:
  - name: {{ server.tokens.location }}
  - mode: 750
  - user: keystone
  - group: keystone
  - require:
    - pkg: keystone_packages
  - require_in:
    - service: keystone_fernet_setup

{%- if not grains.get('noservices', False) %}
keystone_fernet_setup:
  cmd.run:
  - name: keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
  - require:
    - service: keystone_service
    - file: keystone_fernet_keys
{%- endif %}

{% endif %}

{%- if not grains.get('noservices', False) %}

{%- if not salt['pillar.get']('linux:system:repo:mirantis_openstack', False) %}

keystone_service_tenant:
  keystone.tenant_present:
  - name: {{ server.service_tenant }}
  - connection_token: {{ server.service_token }}
  - connection_endpoint: 'http://{{ server.bind.address }}:{{ server.bind.private_port }}/v2.0'
  - require:
    - cmd: keystone_syncdb
    - file: keystone_salt_config

keystone_admin_tenant:
  keystone.tenant_present:
  - name: {{ server.admin_tenant }}
  - connection_token: {{ server.service_token }}
  - connection_endpoint: 'http://{{ server.bind.address }}:{{ server.bind.private_port }}/v2.0'
  - require:
    - keystone: keystone_service_tenant

keystone_roles:
  keystone.role_present:
  - names: {{ server.roles }}
  - connection_token: {{ server.service_token }}
  - connection_endpoint: 'http://{{ server.bind.address }}:{{ server.bind.private_port }}/v2.0'
  - require:
    - keystone: keystone_service_tenant

keystone_admin_user:
  keystone.user_present:
  - name: {{ server.admin_name }}
  - password: {{ server.admin_password }}
  - email: {{ server.admin_email }}
  - tenant: {{ server.admin_tenant }}
  - roles:
      {{ server.admin_tenant }}:
      - admin
  - connection_token: {{ server.service_token }}
  - connection_endpoint: 'http://{{ server.bind.address }}:{{ server.bind.private_port }}/v2.0'
  - require:
    - keystone: keystone_admin_tenant
    - keystone: keystone_roles

{%- endif %}

{%- for service_name, service in server.get('service', {}).iteritems() %}

keystone_{{ service_name }}_service:
  keystone.service_present:
  - name: {{ service_name }}
  - service_type: {{ service.type }}
  - description: {{ service.description }}
  - connection_token: {{ server.service_token }}
  - connection_endpoint: 'http://{{ server.bind.address }}:{{ server.bind.private_port }}/v2.0'
  - require:
    - keystone: keystone_roles

keystone_{{ service_name }}_endpoint:
  keystone.endpoint_present:
  - name: {{ service.get('service', service_name) }}
  - publicurl: '{{ service.bind.get('public_protocol', 'http') }}://{{ service.bind.public_address }}:{{ service.bind.public_port }}{{ service.bind.public_path }}'
  - internalurl: '{{ service.bind.get('internal_protocol', 'http') }}://{{ service.bind.internal_address }}:{{ service.bind.internal_port }}{{ service.bind.internal_path }}'
  - adminurl: '{{ service.bind.get('admin_protocol', 'http') }}://{{ service.bind.admin_address }}:{{ service.bind.admin_port }}{{ service.bind.admin_path }}'
  - region: {{ service.get('region', 'RegionOne') }}
  - connection_token: {{ server.service_token }}
  - connection_endpoint: 'http://{{ server.bind.address }}:{{ server.bind.private_port }}/v2.0'
  - require:
    - keystone: keystone_{{ service_name }}_service
    - file: keystone_salt_config

{% if service.user is defined %}

keystone_user_{{ service.user.name }}:
  keystone.user_present:
  - name: {{ service.user.name }}
  - password: {{ service.user.password }}
  - email: {{ server.admin_email }}
  - tenant: {{ server.service_tenant }}
  - roles:
      {{ server.service_tenant }}:
      - admin
  - connection_token: {{ server.service_token }}
  - connection_endpoint: 'http://{{ server.bind.address }}:{{ server.bind.private_port }}/v2.0'
  - require:
    - keystone: keystone_roles

{% endif %}

{%- endfor %}

{%- for tenant_name, tenant in server.get('tenant', {}).iteritems() %}

keystone_tenant_{{ tenant_name }}:
  keystone.tenant_present:
  - name: {{ tenant_name }}
  - connection_token: {{ server.service_token }}
  - connection_endpoint: 'http://{{ server.bind.address }}:{{ server.bind.private_port }}/v2.0'
  - require:
    - keystone: keystone_roles

{%- for user_name, user in tenant.get('user', {}).iteritems() %}

keystone_user_{{ user_name }}:
  keystone.user_present:
  - name: {{ user_name }}
  - password: {{ user.password }}
  - email: {{ user.get('email', 'root@localhost') }}
  - tenant: {{ tenant_name }}
  - roles:
      {{ tenant_name }}:
      {%- if user.get('roles', False) %}
      {{ user.roles }}
      {%- else %}
      - Member
      {%- endif %}
  - connection_token: {{ server.service_token }}
  - connection_endpoint: 'http://{{ server.bind.address }}:{{ server.bind.private_port }}/v2.0'
  - require:
    - keystone: keystone_tenant_{{ tenant_name }}

{%- endfor %}

{%- endfor %}
{%- endif %} {# end noservices #}

{%- endif %}
