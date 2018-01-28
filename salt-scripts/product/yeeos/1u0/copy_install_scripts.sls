{#
copy_config_install:
  file.managed:
    - name: /opt/copy_install_scripts.sh
    - source:
      - salt://product/yeeos/1u0/package/copy_install_scripts.sh

clean_old_package:
  cmd.run:
    - name: /bin/bash /opt/copy_install_scripts.sh
    - require:
      - file: /opt/copy_install_scripts.sh

#}

copy_install_scripts:
  file.copy:
    - name: /opt/YeeOS1.0_install
    - source: /testing/share/svn/TestRepository/TestScripts/YeeOS/YeeOS1.0_install
    - force: True
