base:
  '*':
    - hosts
    - resolv
  'worker*':
    - users
    - repositories
    - docker
    - etcdctl
    - fleet
  'etcd*':
    - users
    - repositories
    - etcd
    - etcdctl
  'commander':
    - dnsmasq
    - users
    - repositories
    - fleet
    - etcdctl
    - nginx
