{% set local_ip = pillar.get("local_ip") %}

set_host_name:
  cmd.run:
    - name: hostname {{'HOST' + local_ip.split('.')[-2]+local_ip.split('.')[-1] }}
