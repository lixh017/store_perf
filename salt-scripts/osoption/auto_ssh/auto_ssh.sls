config_ssh:
  cmd.run:
    - name : grep -w "StrictHostKeyChecking no" /etc/ssh/ssh_config >> /dev/null 2>&1 ; if [ $? -ne 0 ] ;then echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config;fi
dir_removed:
  cmd.run:
    - name: rm -rf /root/.ssh/

dir_create:
  file.directory:
    - name: /root/.ssh
    - user: root
    - group: root
    - dir_mode: 700

id_rsa:
  file.managed:
    - name: /root/.ssh/id_rsa
    - source: 
      - salt://osoption/auto_ssh/id_rsa
    - user: root
    - group: root 
    - mode: 600

id_rsa.pub:
  file.managed:
    - name: /root/.ssh/id_rsa.pub
    - source: 
      - salt://osoption/auto_ssh/id_rsa.pub
    - user: root
    - group: root 
    - mode: 644

authorized_keys:
  file.managed:
    - name: /root/.ssh/authorized_keys
    - source: 
      - salt://osoption/auto_ssh/authorized_keys
    - user: root
    - group: root 
    - mode: 644
