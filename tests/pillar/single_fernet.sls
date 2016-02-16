keystone:
  server:
    enabled: true
    version: liberty
    service_token: token
    service_tenant: service
    admin_tenant: admin
    admin_name: admin
    admin_password: password
    admin_email: root@localhost
    bind:
      address: 0.0.0.0
      private_address: 127.0.0.1
      private_port: 35357
      public_address: 127.0.0.1
      public_port: 5000
    region: RegionOne
    database:
      engine: mysql
      host: 'localhost'
      name: 'keystone'
      password: 'password'
      user: 'keystone'
    tokens:
      engine: fernet
      expiration: 86400
      location: /etc/keystone/fernet-keys/
    cache:
      engine: memcached
      members: 
      - host: localhost
        port: 11211
