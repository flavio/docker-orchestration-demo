hosts:
  file.managed:
    - source: salt://hosts/hosts.jinja
    - name: /etc/hosts
    - template: jinja
    - user: root
    - group: root
    - mode: 644
