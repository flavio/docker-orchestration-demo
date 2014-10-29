#!py
# We have to use a py template because AFAIK _get_etcd_names cannot be done using jinja

def _get_etcd_names():
    return ','.join(['http://{}:4001'.format(n) for n in pillar['nodes'] if 'etcd' in n])


def run():
    if 'worker-big' in grains['localhost']:
        metadata = "size=big"
    else:
        metadata = "size=small"

    config = """# This config file is INI-formatted
# Lower the logging threshold. Acceptable values are 0, 1, and 2. A higher
# value corresponds to a lower logging threshold.
# verbosity=0
# Provide a custom set of etcd endpoints. The default value is determined
# by the underlying go-etcd library.
etcd_servers=["{etcd_servers}"]
# Amount of time in seconds to allow a single etcd request before considering it failed.
# etcd_request_timeout=1.0
# Provide TLS configuration when SSL certificate authentication is enabled in etcd endpoints
# etcd_cafile=/path/to/CAfile
# etcd_keyfile=/path/to/keyfile
# etcd_certfile=/path/to/certfile
# IP address that should be published with any socket information. By default,
# no IP address is published.
public_ip="{hostname}"
# Comma-delimited key/value pairs that are published to the fleet registry.
# This data can be referenced in unit files to affect scheduling descisions.
# An example could look like: metadata="region=us-west,az=us-west-1"
metadata="{metadata}"
# An Agent will be considered dead if it exceeds this amount of time to
# communicate with the Registry. The agent will attempt a heartbeat at half
# of this value.
# agent_ttl="30s"
# Interval at which the engine should reconcile the cluster schedule in etcd.
# engine_reconcile_interval=2""".format(
    metadata = metadata,
    etcd_servers=_get_etcd_names(),
    hostname=grains['localhost'])

    return config
