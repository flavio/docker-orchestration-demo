etcd:
  pkg:
    - installed
    - require:
      - file: docker_ecosystem_repo
  service:
    - running
    - enable: True
    - require:
      - pkg: etcd
      - file: etcd_conf
    - watch:
      - file: etcd_conf

etcd_conf:
  file.managed:
    - source: salt://etcd/etcd.conf.py
    - name: /etc/etcd/etcd.conf
    - template: py
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: etcd
