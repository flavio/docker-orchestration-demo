docker_ecosystem_repo:
  file.managed:
    - source: salt://repositories/docker_ecosystem.repo
    - name: /etc/zypp/repos.d/docker_ecosystem.repo
    - user: root
    - group: root
    - mode: 644

{% if salt['grains.get']('localhost', '') == 'commander' %}
nginx_repo:
  file.managed:
    - source: salt://repositories/nginx.repo
    - name: /etc/zypp/repos.d/nginx.repo
    - user: root
    - group: root
    - mode: 644
{% endif %}

