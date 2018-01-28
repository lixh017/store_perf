fio_remove:
  cmd.run:
    - name: rm -rf /usr/bin/iozone 

fio_download:
  file.managed:
  - name: /usr/bin/iozone
  - source: 
    - http://172.16.16.5/testtools/iozone/iozone
  - skip_verify: True
  - user: root
  - group: root
  - mode: 777

