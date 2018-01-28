{% if grains['os'] == 'CentOS' and grains['osmajorrelease'] == '7' %}

fio_remove:
  cmd.run:
    - name: rpm -qa|grep fio >> /dev/null 2>&1 ; if [ $? -eq 0 ] ; then rpm -e fio ; fi 
fio_download:
  file.managed:
  - name: /opt/fio-2.2.10-1.el7.x86_64.rpm 
  - source: 
    - http://172.16.16.5/testtools/fio/fio-2.2.10-1.el7.x86_64.rpm
  - skip_verify: True

fio_install:
  cmd.run:
    - name: yum -y install /opt/fio-2.2.10-1.el7.x86_64.rpm
    - require:
      - file: /opt/fio-2.2.10-1.el7.x86_64.rpm

{% endif %}
