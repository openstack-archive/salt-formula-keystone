==================
OpenStack Keystone
==================

Keystone provides authentication, authorization and service discovery
mechanisms via HTTP primarily for use by projects in the OpenStack family. It
is most commonly deployed as an HTTP interface to existing identity systems,
such as LDAP.

From Kilo release Keystone v3 endpoint has definition without version in url

.. code-block:: bash

  +----------------------------------+-----------+--------------------------+--------------------------+---------------------------+----------------------------------+
  |                id                |   region  |        publicurl         |       internalurl        |          adminurl         |            service_id            |
  +----------------------------------+-----------+--------------------------+--------------------------+---------------------------+----------------------------------+
  | 91663a8db11c487c9253c8c456863494 | RegionOne | http://10.0.150.37:5000/ | http://10.0.150.37:5000/ | http://10.0.150.37:35357/ | 0fd2dba3153d45a1ba7f709cfc2d69c9 |
  +----------------------------------+-----------+--------------------------+--------------------------+---------------------------+----------------------------------+


Sample pillars
==============

.. caution::

    When you use localhost as your database host (keystone:server:
    atabase:host), sqlalchemy will try to connect to /var/run/mysql/
    mysqld.sock, may cause issues if you located your mysql socket elsewhere

Full stacked keystone

.. code-block:: yaml

    keystone:
      server:
        enabled: true
        version: juno
        service_token: 'service_tokeen'
        service_tenant: service
        service_password: 'servicepwd'
        admin_tenant: admin
        admin_name: admin
        admin_password: 'adminpwd'
        admin_email: stackmaster@domain.com
        roles:
          - admin
          - Member
          - image_manager
        bind:
          address: 0.0.0.0
          private_address: 127.0.0.1
          private_port: 35357
          public_address: 127.0.0.1
          public_port: 5000
        api_version: 2.0
        region: RegionOne
        database:
          engine: mysql
          host: '127.0.0.1'
          name: 'keystone'
          password: 'LfTno5mYdZmRfoPV'
          user: 'keystone'

Keystone public HTTPS API

.. code-block:: yaml

    keystone:
      server:
        enabled: true
        version: juno
        ...
        services:
        - name: nova
          type: compute
          description: OpenStack Compute Service
          user:
            name: nova
            password: password
          bind:
            public_address: cloud.domain.com
            public_protocol: https
            public_port: 8774
            internal_address: 10.0.0.20
            internal_port: 8774
            admin_address: 10.0.0.20
            admin_port: 8774

Keystone memcached storage for tokens

.. code-block:: yaml

    keystone:
      server:
        enabled: true
        version: juno
        ...
        token_store: cache
        cache:
          engine: memcached
          host: 127.0.0.1
          port: 11211
        services:
        ...

Keystone clustered memcached storage for tokens

.. code-block:: yaml

    keystone:
      server:
        enabled: true
        version: juno
        ...
        token_store: cache
        cache:
          engine: memcached
          members:
          - host: 192.160.0.1
            port: 11211
          - host: 192.160.0.2
            port: 11211
        services:
        ...

Keystone client

.. code-block:: yaml

    keystone:
      client:
        enabled: true
        server:
          host: 10.0.0.2
          public_port: 5000
          private_port: 35357
          service_token: 'token'
          admin_tenant: admin
          admin_name: admin
          admin_password: 'passwd'

Keystone cluster

.. code-block:: yaml

    keystone:
      control:
        enabled: true
        provider:
          os15_token:
            host: 10.0.0.2
            port: 35357
            token: token
          os15_tcp_core_stg:
            host: 10.0.0.5
            port: 5000
            tenant: admin
            name: admin
            password: password

Keystone fernet tokens for OpenStack Kilo release

.. code-block:: yaml

    keystone:
      server:
        ...
        tokens:
          engine: fernet
          max_active_keys: 3
        ...

Keystone domain with LDAP backend, using SQL for role/project assignment

.. code-block:: yaml

    keystone:
      server:
        domain:
          description: "Testing domain"
          backend: ldap
          assignment:
            backend: sql
          ldap:
            url: "ldaps://idm.domain.com"
            suffix: "dc=cloud,dc=domain,dc=com"
            # Will bind as uid=keystone,cn=users,cn=accounts,dc=cloud,dc=domain,dc=com
            uid: keystone
            password: password

Using LDAP backend for default domain

.. code-block:: yaml

    keystone:
      server:
        backend: ldap
        assignment:
          backend: sql
        ldap:
          url: "ldaps://idm.domain.com"
          suffix: "dc=cloud,dc=domain,dc=com"
          # Will bind as uid=keystone,cn=users,cn=accounts,dc=cloud,dc=domain,dc=com
          uid: keystone
          password: password

Simple service endpoint definition (defaults to RegionOne)

.. code-block:: yaml

    keystone:
      server:
        service:
          ceilometer:
            type: metering
            description: OpenStack Telemetry Service
            user:
              name: ceilometer
              password: password
            bind:
              ...

Region-aware service endpoints definition

.. code-block:: yaml

    keystone:
      server:
        service:
          ceilometer_region01:
            service: ceilometer
            type: metering
            region: region01
            description: OpenStack Telemetry Service
            user:
              name: ceilometer
              password: password
            bind:
              ...
          ceilometer_region02:
            service: ceilometer
            type: metering
            region: region02
            description: OpenStack Telemetry Service
            bind:
              ...

Enable ceilometer notifications

.. code-block:: yaml

    keystone:
      server:
        notification: true
        message_queue:
          engine: rabbitmq
          host: 127.0.0.1
          port: 5672
          user: openstack
          password: password
          virtual_host: '/openstack'
          ha_queues: true

Enable CADF audit notification

.. code-block:: yaml

    keystone:
      server:
        notification: true
        notification_format: cadf

Run keystone under Apache

.. code-block:: yaml

    keystone:
      server:
        service_name: apache2
    apache:
      server:
        enabled: true
        default_mpm: event
        site:
          keystone:
            enabled: true
            type: keystone
            name: wsgi
            host:
              name: ${linux:network:fqdn}
        modules:
          - wsgi

Enable Federated keystone

.. code-block:: yaml

    keystone:
      server:
        websso:
          protocol: saml2
          remote_id_attribute: Shib-Identity-Provider
          federation_driver: keystone.contrib.federation.backends.sql.Federation
          trusted_dashboard:
            - http://${_param:proxy_vip_address_public}/horizon/auth/websso/
    apache:
      server:
        pkgs:
          - apache2
          - libapache2-mod-shib2
        modules:
          - wsgi
          - shib2

Keystone client
---------------

Service endpoints enforcement with service token

.. code-block:: yaml

    keystone:
      client:
        enabled: true
        server:
          keystone01:
            admin:
              host: 10.0.0.2
              port: 35357
              token: 'service_token'
            service:
              nova:
                type: compute
                description: OpenStack Compute Service
                endpoints:
                - region: region01
                  public_address: 172.16.10.1
                  public_port: 8773
                  public_path: '/v2'
                  internal_address: 172.16.10.1
                  internal_port: 8773
                  internal_path: '/v2'
                  admin_address: 172.16.10.1
                  admin_port: 8773
                  admin_path: '/v2'

Project, users, roles enforcement with admin user

.. code-block:: yaml

    keystone:
      client:
        enabled: true
        server:
          keystone01:
            admin:
              host: 10.0.0.2
              port: 5000
              project: 'token'
              user: admin
              password: 'passwd'
            roles:
            - admin
            - member
            project:
              tenant01:
                description: "test env"
                user:
                  user01:
                    email: jdoe@domain.com
                    is_admin: true
                    password: some
                  user02:
                    email: jdoe2@domain.com
                    password: some
                    roles:
                    - custom-roles

Documentation and Bugs
======================

To learn how to deploy OpenStack Salt, consult the documentation available
online at:

    https://wiki.openstack.org/wiki/OpenStackSalt

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate bug tracker. If you obtained the software from a 3rd party
operating system vendor, it is often wise to use their own bug tracker for
reporting problems. In all other cases use the master OpenStack bug tracker,
available at:

    http://bugs.launchpad.net/openstack-salt

Developers wishing to work on the OpenStack Salt project should always base
their work on the latest formulas code, available from the master GIT
repository at:

    https://git.openstack.org/cgit/openstack/salt-formula-keystone

Developers should also join the discussion on the IRC list, at:

    https://wiki.openstack.org/wiki/Meetings/openstack-salt
