resolv_conf:
  file.managed:
    - source: salt://resolv/resolv.conf.jinja
    - name: /etc/resolv.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
{% if salt['grains.get']('localhost', '') == 'commander' %}
    - require:
      - service: dnsmasq
      - file: dnsmasq_conf
{% endif %}
