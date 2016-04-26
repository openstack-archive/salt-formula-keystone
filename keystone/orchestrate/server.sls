{%- if grains['saltversion'] >= "2016.3.0" %}

{# Batch execution is necessary - usable after 2016.3.0 release #}
keystone.server:
  salt.state:
    - tgt: 'keystone:server'
    - tgt_type: pillar
    - batch: 1
    - sls: keystone.server

{%- else %}

{# Workaround for cluster with up to 3 members #}
keystone.server:
  salt.state:
    - tgt: '*01* and I@keystone:server'
    - tgt_type: compound
    - sls: keystone.server

keystone.server.02:
  salt.state:
    - tgt: '*02* and I@keystone:server'
    - tgt_type: compound
    - sls: keystone.server

keystone.server.03:
  salt.state:
    - tgt: '*03* and I@keystone:server'
    - tgt_type: compound
    - sls: keystone.server

{%- endif %}

