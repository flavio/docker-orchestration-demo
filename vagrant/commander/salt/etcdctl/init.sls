etcdctl:
  pkg:
    - installed
    - require:
      - file: docker_ecosystem_repo

etcdctl_conf:
  file.managed:
    - source: salt://etcdctl/etcdctl.conf.py
    - name: /etc/etcdctl.conf
    - user: root
    - group: root
    - mode: 755
    - template: py

