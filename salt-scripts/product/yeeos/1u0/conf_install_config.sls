{% set str= pillar.get("option") %}
{% set conf_file = '/opt/YeeOS1.0_install/install.conf' %}

remove_conf:
  cmd.run:
    - name: rm -rf {{conf_file}}

{% for key in str.keys() %} 
append_conf_{{key}}:
  file.append:
    - name: {{conf_file}}
    - text: {{key}}="{{str[key]}}"
 
{% endfor %}
