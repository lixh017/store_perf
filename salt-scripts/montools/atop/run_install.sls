{% set os_list = ['XenServer 7.1.0', %}
test:
  cmd.run:
    - name: echo {{os}}

fio_remove:
  cmd.run:
    - name: rpm -qa|grep atop >> /dev/null 2>&1 ; if [ $? -eq 0 ] ; then rpm -e atop ; fi 

{% if grains['os'] == 'CentOS' or grains['os'] == 'XenServer' %}
fio_download:
  file.managed:
  - name: /opt/atop-2.0.2-4.el7.x86_64.rpm
  - source:
    - http://172.16.16.5/testtools/atop/atop-2.0.2-4.el7.x86_64.rpm
  - skip_verify: True

{#
{% elif grains['osmajorrelease'] == '6' %}
fio_download:
  file.managed:
  - name: /opt/atop-1.27-2.el6.x86_64.rpm
  - source:
    - http://172.16.16.5/testtools/atop/atop-1.27-2.el6.x86_64.rpm
  - skip_verify: True
  {% endif %}

{% if grains['osmajorrelease'] == '7' %}
fio_install:
  cmd.run:
    - name: yum -y install /opt/atop-2.0.2-4.el7.x86_64.rpm
    - require:
      - file: /opt/atop-2.0.2-4.el7.x86_64.rpm

{% elif grains['osmajorrelease'] == '6' %}
fio_install:
  cmd.run:
    - name: yum -y install /opt/atop-1.27-2.el6.x86_64.rpm
    - require:
      - file: /opt/atop-1.27-2.el6.x86_64.rpm
#}
{% endif %}

