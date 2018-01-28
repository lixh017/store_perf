{% set ip_str= pillar.get("ip_list") %}
{% set ip_list = ip_str.split(',') %}

{% for ipaddr in ip_list %}
{% set hostname = 'HOST'+ ipaddr.split('.')[-2]+ipaddr.split('.')[-1] %}
config_hosts_{{ipaddr}}:
  host.present:
    - ip: {{ipaddr}}
    - names: 
      - {{hostname}}
{% endfor %}
