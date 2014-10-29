fleet:
  pkg:
    - installed
{% if salt['grains.get']('localhost', '') != 'commander' %}
  service:
    - running
    - enable: True
    - require:
      - pkg: fleet
      - file: docker_ecosystem_repo
      - file: fleet_conf
{% endif %}

fleet_conf:
  file.managed:
    - source: salt://fleet/fleet.conf.py
    - name: /etc/fleet/fleet.conf
    - template: py
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: fleet
