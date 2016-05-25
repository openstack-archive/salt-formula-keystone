{%- from "keystone/map.jinja" import server with context -%}
#!/bin/bash -e

cat /srv/salt/pillar/keystone-server.sls | envsubst > /tmp/keystone-server.sls
mv /tmp/keystone-server.sls /srv/salt/pillar/keystone-server.sls

salt-call --local --retcode-passthrough state.highstate
service {{ server.service_name }} stop || true

su keystone --shell=/bin/sh -c '/usr/bin/keystone-all --config-file=/etc/keystone/keystone.conf'

{#-
vim: syntax=jinja
-#}
