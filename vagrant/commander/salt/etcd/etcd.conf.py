#!py
# We have to use a py template because AFAIK _get_etcd_names cannot be done using jinja

def _get_etcd_names():
  return ','.join(['{}:7001'.format(n) for n in pillar['nodes'] if 'etcd' in n])

def run():
  config = """# etcd configuration file, for more details
# read https://github.com/coreos/etcd/blob/master/Documentation/configuration.md
addr = "{ip}:4001"
bind = "{ip}:4001"
verbose = false
very_verbose = false

[peer]
addr = "{etcd_names}"
bind = "{ip}:7001"
""".format(ip=grains['localhost'], etcd_names=_get_etcd_names())

  return config
