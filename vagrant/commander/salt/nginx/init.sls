nginx:
  pkg:
    - installed
    - require:
      - file: nginx_repo
  service:
    - running
    - enable: True
    - require:
      - pkg: nginx
    - watch:
      - file: nginx_conf

nginx_conf:
  file.managed:
    - source: salt://nginx/nginx.conf.jinja
    - name: /etc/nginx/nginx.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx
