#!py
# We have to use a py template because AFAIK _get_etcd_names cannot be done using jinja


def _get_etcd_urls():
    return ['http://{}:4001'.format(n) for n in pillar['nodes'] if 'etcd' in n]


def run():
    etcd_urls = ','.join(_get_etcd_urls())

    config = """
if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval `ssh-agent -s`
  ssh-add
fi

export FLEETCTL_ENDPOINT="{etcd_urls}"
export ETCDCTL_PEERS="{etcd_urls}"

""".format(etcd_urls=etcd_urls)

    return config
