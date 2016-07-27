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

Documentation and Bugs
============================

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

Development and testing
=======================

Development and test workflow with `Test Kitchen <http://kitchen.ci>`_ and
`kitchen-salt <https://github.com/simonmcc/kitchen-salt>`_ provisioner plugin.

Test Kitchen is a test harness tool to execute your configured code on one or more platforms in isolation.
There is a ``.kitchen.yml`` in main directory that defines *platforms* to be tested and *suites* to execute on them.

Kitchen CI can spin instances locally or remote, based on used *driver*.
For local development ``.kitchen.yml`` defines a `vagrant <https://github.com/test-kitchen/kitchen-vagrant>`_ or
`docker  <https://github.com/test-kitchen/kitchen-docker>`_ driver.

To use backend drivers or implement your CI follow the section `INTEGRATION.rst#Continuous Integration`__.

A listing of scenarios to be executed:

.. code-block:: shell

  $ kitchen list

  Instance                    Driver   Provisioner  Verifier  Transport  Last Action

  cluster-ubuntu-1404        Vagrant  SaltSolo     Inspec    Ssh        <Not Created>
  cluster-ubuntu-1604        Vagrant  SaltSolo     Inspec    Ssh        <Not Created>
  cluster-centos-71          Vagrant  SaltSolo     Inspec    Ssh        <Not Created>
  single-fernet-ubuntu-1404  Vagrant  SaltSolo     Inspec    Ssh        <Not Created>
  single-fernet-ubuntu-1604  Vagrant  SaltSolo     Inspec    Ssh        <Not Created>
  single-fernet-centos-71    Vagrant  SaltSolo     Inspec    Ssh        <Not Created>
  single-ubuntu-1404         Vagrant  SaltSolo     Inspec    Ssh        <Not Created>
  single-ubuntu-1604         Vagrant  SaltSolo     Inspec    Ssh        <Not Created>
  single-centos-71           Vagrant  SaltSolo     Inspec    Ssh        <Not Created>

The `Busser <https://github.com/test-kitchen/busser>`_ *Verifier* is used to setup and run tests
implementated in `<repo>/test/integration`. It installs the particular driver to tested instance
(`Serverspec <https://github.com/neillturner/kitchen-verifier-serverspec>`_,
`InSpec <https://github.com/chef/kitchen-inspec>`_, Shell, Bats, ...) prior the verification is executed.


Usage:

.. code-block:: shell

 # list instances and status
 kitchen list

 # manually execute integration tests
 kitchen [test || [create|converge|verify|exec|login|destroy|...]] [instance] -t tests/integration

 # use with provided Makefile (ie: within CI pipeline)
 make kitchen

