mk_tgt_dir:
  cmd.run:
    - name: mkdir -p /opt/
copy_clean_script:
  file.managed:
    - name: /opt/yeeos_clean.sh
    - source:
      - salt://product/yeeos/1u0/package/yeeos_clean.sh
    - user: root
    - group: root
    - mode: 777

run_clean:
  cmd.run:
    - name: /bin/bash /opt/yeeos_clean.sh
    - require:
      - file: /opt/yeeos_clean.sh

