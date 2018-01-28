fio_remove:
  cmd.run:
    - name: rm -rf /opt/vdbench50406.zip /opt/vdbench

fio_download:
  file.managed:
  - name: /opt/vdbench50406.zip
  - source: 
    - http://172.16.16.5/testtools/vdbench/vdbench50406.zip
  - skip_verify: True

vdbench_install:
  archive.extracted:
    - name: /opt/vdbench
    - source: /opt/vdbench50406.zip
    - require:
      - file: /opt/vdbench50406.zip
    - enforce_toplevel: false

