#!py
# We have to use a py template because AFAIK _get_etcd_urls cannot be done using jinja


def _get_etcd_urls():
    return ['http://{}:4001'.format(n) for n in pillar['nodes'] if 'etcd' in n]


def run():
    etcd_urls = ','.join(_get_etcd_urls())
    config = 'ETCDCTL_PEERS="{etcd_urls}"\n'.format(etcd_urls=etcd_urls)

    return config
