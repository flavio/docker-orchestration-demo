# Creates a 'core' user with 'core' as password.
# The ssh keys' are the one used by vagrant.

core:
  user.present:
    - shell: /bin/bash
    - home: /home/core
    - createhome: True
    - password: $6$mOSU20H.O/Iefz$3op7bKYz4crSyDbs8r1mIP/WtcV4vBSeFGhRir.matRcryuxe.nI.bPy59QfVt1QnCbGZ0NkQrBGmO1iU16Br0
    - enforce_password: True
{% if 'worker' in salt['grains.get']('host', '') %}
    - groups:
      - docker
    - require:
      - pkg: docker
{% endif %}

authorized_keys:
  file.managed:
    - source: salt://users/authorized_keys
    - name: /home/core/.ssh/authorized_keys
    - user: core
    - group: users
    - mode: 600
    - require:
      - file: core_ssh_dir

vagrant_ssh_key_private:
  file.managed:
    - source: salt://users/vagrant
    - name: /home/core/.ssh/id_rsa
    - user: core
    - group: users
    - mode: 600
    - require:
      - file: core_ssh_dir

vagrant_ssh_key_public:
  file.managed:
    - source: salt://users/vagrant.pub
    - name: /home/core/.ssh/id_rsa.pub
    - user: core
    - group: users
    - mode: 600
    - require:
      - file: core_ssh_dir

core_ssh_dir:
  file.directory:
    - name: /home/core/.ssh/
    - user: core
    - group: users
    - mode: 700
    - makedirs: True
    - require:
      - user: core

core_bashrc:
  file.managed:
    - source: salt://users/core_bashrc.py
    - name: /home/core/.bashrc
    - user: core
    - group: users
    - mode: 755
    - template: py
    - require:
      - file: core_ssh_dir

