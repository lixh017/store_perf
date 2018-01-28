copy_systemctl:
  file.managed:
    - name : /usr/lib/systemd/system/vdbench-server.service 
    - source:
      - salt://testtools/vdbench/package/vdbench-server.service
    - user: root
    - group: root
    - mode: 754

copy_start_script:
  file.managed:
    - name : /opt/start_vdbench_rsh.sh
    - source:
      - salt://testtools/vdbench/package/start_vdbench_rsh.sh
    - user: root
    - group: root
    - mode: 755

enable_systemctl:
  cmd.run:
    - name: systemctl enable vdbench-server.service

start_systemctl:
  cmd.run:
    - name: systemctl restart vdbench-server
