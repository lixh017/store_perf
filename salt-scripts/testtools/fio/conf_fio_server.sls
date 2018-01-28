copy_systemctl:
  file.managed:
    - name : /usr/lib/systemd/system/fio-server.service 
    - source:
      - salt://testtools/fio/package/fio-server.service
    - user: root
    - group: root
    - mode: 754

enable_systemctl:
  cmd.run:
    - name: systemctl enable fio-server.service

start_systemctl:
  cmd.run:
    - name: systemctl restart fio-server
