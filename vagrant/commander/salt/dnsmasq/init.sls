dnsmasq:
  pkg:
    - installed
  service:
    - running
    - enable: True
    - require:
      - pkg: dnsmasq
    - watch:
      - file: dnsmasq_conf

dnsmasq_conf:
  file.managed:
    - source: salt://dnsmasq/dnsmasq.conf
    - name: /etc/dnsmasq.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: dnsmasq
