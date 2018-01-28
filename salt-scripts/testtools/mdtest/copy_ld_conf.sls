openmpi-x86_64.conf:
  file.managed:
    - name: /etc/ld.so.conf.d/openmpi-x86_64.conf 
    - source: 
      - salt://testtools/mdtest/package/openmpi-x86_64.conf 

env_config:
  cmd.run:
    - name: ldconfig

