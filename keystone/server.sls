{%- from "keystone/map.jinja" import server with context %}
{%- if server.enabled %}

keystone_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

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


/etc/keystone/keystone-paste.ini:
  file.managed:
  - source: salt://keystone/files/{{ server.version }}/keystone-paste.ini.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: keystone_packages
  - watch_in:
    - service: keystone_service

/etc/keystone/policy.json:
  file.managed:
  - source: salt://keystone/files/{{ server.version }}/policy-v{{ server.api_version }}.json
  - require:
    - pkg: keystone_packages
  - watch_in:
    - service: keystone_service

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
    - watch_in:
      - service: keystone_service
    - defaults:
        domain_name: {{ domain_name }}

{%- if domain.get('ldap', {}).get('tls', {}).get('cacert', False) %}

keystone_domain_{{ domain_name }}_cacert:
  file.managed:
    - name: /etc/keystone/domains/{{ domain_name }}.pem
    - contents_pillar: keystone:server:domain:{{ domain_name }}:ldap:tls:cacert
    - require:
      - file: /etc/keystone/domains
    - watch_in:
      - service: keystone_service

{%- endif %}

keystone_domain_{{ domain_name }}:
  cmd.run:
    - name: source /root/keystonercv3 && openstack domain create --description "{{ domain.description }}" {{ domain_name }}
    - unless: source /root/keystonercv3 && openstack domain list | grep " {{ domain_name }}"
    - require:
      - file: /root/keystonercv3
      - service: keystone_service

{%- endfor %}

{%- endif %}

{%- if server.get('ldap', {}).get('tls', {}).get('cacert', False) %}

keystone_ldap_default_cacert:
  file.managed:
    - name: {{ server.ldap.tls.cacertfile }}
    - contents_pillar: keystone:server:ldap:tls:cacert
    - require:
      - pkg: keystone_packages
    - watch_in:
      - service: keystone_service

{%- endif %}

keystone_service:
  service.running:
  - name: {{ server.service_name }}
  - enable: True
  - watch:
    - file: /etc/keystone/keystone.conf

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

keystone_syncdb:
  cmd.run:
  - name: keystone-manage db_sync
  - require:
    - service: keystone_service

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

keystone_fernet_setup:
  cmd.run:
  - name: keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
  - require:
    - service: keystone_service
    - file: keystone_fernet_keys

{% endif %}

keystone_service_tenant:
  keystone.tenant_present:
  - name: {{ server.service_tenant }}
  - require:
    - cmd: keystone_syncdb

keystone_admin_tenant:
  keystone.tenant_present:
  - name: {{ server.admin_tenant }}
  - require:
    - keystone: keystone_service_tenant

keystone_roles:
  keystone.role_present:
  - names: {{ server.roles }}
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
  - require:
    - keystone: keystone_admin_tenant
    - keystone: keystone_roles

{% for service_name, service in server.get('service', {}).iteritems() %}

keystone_{{ service_name }}_service:
  keystone.service_present:
  - name: {{ service_name }}
  - service_type: {{ service.type }}
  - description: {{ service.description }}
  - require:
    - keystone: keystone_roles

keystone_{{ service_name }}_endpoint:
  keystone.endpoint_present:
  - name: {{ service.get('service', service_name) }}
  - publicurl: '{{ service.bind.get('public_protocol', 'http') }}://{{ service.bind.public_address }}:{{ service.bind.public_port }}{{ service.bind.public_path }}'
  - internalurl: '{{ service.bind.get('internal_protocol', 'http') }}://{{ service.bind.internal_address }}:{{ service.bind.internal_port }}{{ service.bind.internal_path }}'
  - adminurl: '{{ service.bind.get('admin_protocol', 'http') }}://{{ service.bind.admin_address }}:{{ service.bind.admin_port }}{{ service.bind.admin_path }}'
  - region: {{ service.get('region', 'RegionOne') }}
  - require:
    - keystone: keystone_{{ service_name }}_service

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
  - require:
    - keystone: keystone_roles

{% endif %}

{% endfor %}

{%- for tenant_name, tenant in server.get('tenant', {}).iteritems() %}

keystone_tenant_{{ tenant_name }}:
  keystone.tenant_present:
  - name: {{ tenant_name }}
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
  - require:
    - keystone: keystone_tenant_{{ tenant_name }}

{%- endfor %}

{%- endfor %}

{%- endif %}
