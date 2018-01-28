copy_mdtest_bin:
  file.managed:
    - name: /usr/bin/mdtest
{% if grains['os'] == 'CentOS' and grains['osrelease'] == '7.1.1503' %}
    - source: 
      - salt://testtools/mdtest/package/CentOS7.1.1503/mdtest
{% elif grains['os'] == 'CentOS' and grains['osrelease'] == '7.2.1511' %}
    - source: 
      - salt://testtools/mdtest/package/CentOS7.2.1511/mdtest
{% elif grains['os'] == 'XenServer' and grains['osrelease'] == '7.1.0' %}
    - source: 
      - salt://testtools/mdtest/package/CentOS7.2.1511/mdtest
{% endif %}
    - user: root
    - group: root
    - mode: 755

