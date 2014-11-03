# Docker orchestration demo

This repository contains a demo environment that can be used to play with Docker
orchestration tools.

The whole environment is based on openSUSE 13.2 as Docker host.

This experiment has been made during [SUSE Hackweek](https://hackweek.suse.com/11/projects/620).

If you are just interested in the orchestration tools I used you can find all
the RPMs inside of [this project](https://build.opensuse.org/project/show/home:flavio_castelli:docker_ecosystem)
on OBS.

## Goal of this test project

The goal of this hackweek project is to deploy a web application talking with 
a database a testing cluster. Both the web application and the
database (MongoDB in this case) are shipped as Docker images.

## Tools used

All the nodes composing the cluster are based on a vanilla openSUSE 13.2 using
BTRFS as main file system.

The demo environment is managed by [Vagrant](https://www.vagrantup.com/) using
[VirtualBox](https://www.virtualbox.org/) as hypervisor.

The provisioning of the demo environment is done using
[SlatStack](http://www.saltstack.com/).

The Docker images are orchestrated using [fleet](https://github.com/coreos/fleet)
and [etcd](https://github.com/coreos/etcd).


## Layout of this repository

This is the layout of the repository:

```
▾ docker_images/
  ▾ guestbook/
    ▾ code/
      ▸ views/
        app.rb
      Dockerfile
▾ services/
    guestbook-http@.service
    mongodb-discovery.service
    mongodb.service
▾ vagrant/
  ▾ commander/
    ▸ pillar/
    ▸ salt/
    provision-commander.sh
    provision-node.sh
    setup_private_network*
  README.md
  Vagrantfile
```

The `docker_images` directory contains the source code of the web application
and the `Dockerfile` file required to ship it as Docker image.

The `services` directory contains the definitions of the services that are going
to be started by `fleet` inside of the cluster.

The `vagrant` directory contains all the files used at deployment time:
  * `commander: this directory contains all the files used by SaltStack.
  * `provision-commander.sh` this is the bash script doing the initial lifting
    required to start the salt server and then run the salt client.
  * `provision-node.sh` this is the bash script doing the initial lifting of
    a worker/etcd node. The script also takes care of invoking the salt client.
  * `setup_private_network`: this is a simple ruby tool required to fix the
    network configuration of the 2nd network of all the nodes.


## Architecture of the cluster

The cluster is composed by a minumum number of 5 nodes.

Each node has the following users:

  * root: with password `vagrant`
  * vagrant: with password `vagrant` and the [official Vagrant ssh key](https://github.com/mitchellh/vagrant/tree/master/keys)
    (this is an insecure passwordless key).
  * core: with password `core`. It also accepts the official Vagrant ssh key.

Each node has two network cards. The 1st one is a VirtualBox NAT device which allows
communication only between the host and the guest. Communication between the nodes
is not working over this interface. The 2nd card is connected to a private
internal network that connects all the nodes of the cluster.

### The 'commander' node

This node is the first one provisioned by Vagrant. It runs the salt master
daemon and a dnsmasq instance acting both as dhcp and dns server. The commander
node is registered against the salt daemon running on itself; that allows all
the services/configurations to be handled by salt.

The Docker fleet is operated from this node. The `etcdctl` tool can be used on
this host as well. Just remember to execute the both tools while logged in as
the `core` user.

There is also an instance of [nginx](http://nginx.org/) used to access the pages
served by the webapp Docker containers.

### The 'etcd' node

This node runs the [etcd](https://github.com/coreos/etcd) daemon required to
coordinate the Docker fleet.

### The 'worker' node

This node has the Docker and the fleet daemons running. The purpose of the node
is to run Docker containers.

### The 'worker-big' node

This node is just like the `worker` node but it simulates a worker node with
more hardware resources (despite its VM is like the `worker` one).

## Playing with the demo

Just follow these steps to see the testing environment in action.

### Create the virtual machines

First of all you need to have vagrant installed. openSUSE users can install it
from the [devel:languages:ruby:extensions project](http://software.opensuse.org/package/rubygem-vagrant)
on OBS.

Ensure you have VirtualBox installed and running. Note: your user must be part
of the `vboxusers` group.

Create all the virtual machines:

```
vagrant up
```

This will download the openSUSE 13.2 base image I created and then it will
provision the nodes using the following order: commander, etcd-1, worker-1,
worker-2 and worker-big-1. All these VMs require 512 Mb or RAM.

You will see a lot of output during the provisioning, that's generated by salt
preparing the nodes. All the salt steps will succeed except for the one starting
the nginx service. That happens because at this point of the provisioning the
worker nodes referenced by nginx have not been created yet.

At the end of the provisioning all the machines will be running:

```
$ vagrant status
Current machine states:

commander                 running (virtualbox)
etcd-1                    running (virtualbox)
worker-1                  running (virtualbox)
worker-2                  running (virtualbox)
worker-big-1              running (virtualbox)
```

You can ssh into any of these machines by doing `vagrant ssh <machine name>`.

### Start the database container

The database container needs to be started first:

   1 - Connect to the commander node: `vagrant ssh commander`
   2 - Change to the `core` user: `sudo su - core`
   3 - Move to the directory containing the service definitions: `cd ~/services`.
       Note: this directory is shared between the virtualization host and this
       guest.
   4 - Start the MongoDB service: `fleetctl start mongodb.service`. This service
       will always start on the `worker-big-1` node because it requires to run
       on a node with the `size=big` metadata set. This requirement is fulfilled
       only by the `worker-big-1` node.

During step #4 the Docker image contaning the MongoDB database is downloaded
from the Docker Hub. You can monitor the status of the operation by doing:

`watch -n 1 "fleetctl list-units"`

In the beginning you will see something like:

```
UNIT    MACHINE       ACTIVE    SUB
mongodb.service 0bedb413.../worker-big-1  activating  start-pre
```

Once the Docker image has been downloaded and started you will see something
like:

```
UNIT        MACHINE       ACTIVE  SUB
mongodb-discovery.service 0bedb413.../worker-big-1  active  running
```

Once the MongoDB service is active you can announce it over the cluster. In
oder to do execute the following command:

```
fleetctl start mongodb-discovery.service
```

This is a [sidekick service](https://coreos.com/docs/launching-containers/launching/launching-containers-fleet/#run-an-external-service-sidekick)
which adds a new entry to the central etcd daemon.

You can view the data created by the sidekick process by doing:

```
etcdctl get /services/mongodb
```

This will returns something like:

```
{ "host": "worker-big-1", "port": 27017 }
```

Now `fleetctl list-units` will return something similar to:
```
UNIT        MACHINE       ACTIVE  SUB
mongodb-discovery.service 0bedb413.../worker-big-1  active  running
mongodb.service     0bedb413.../worker-big-1  active  running
```

### Start the first instance of the web application

Let's start one instance of our web application:

```
fleetctl start guestbook-http@1.service
```

The deployment status can be monitored with the usual
`watch -n 1 "fleetctl list-units"`


You can move to the next step once the service is reported as up and running.

### Access the web application

The nginx daemon need to be started on the commander node:

`sudo systemctl start nginx`

The nginx process listens on port 80 of the commander node, which is mapped by
VirtualBox to port 8080 on the virtualization host.

Hence to access the web application you need to visit `http://localhost:8080`.

### Simulating a hardware failure

Now we are going to simulate the failure of the node running the web application.

Keep a console with the following command running:

`watch -n 1 "fleetctl list-units"`

On the virtualization host execute the following command:

`vagrant halt <name of the node running the guestbook container>`

As soon as the node goes down you will see the `guestbook-http@1` service is
automatically migrated to the other worker node. The 1st "migration" will
take some time since the Docker image has never been downloaded from the
central index to this worker.

Once the container is running you can visit the web application webpage.

### Running more instances of the web application

We can scale our web application (and make it more robust) by running different
instances of it across our small cluster.

Restart the worker node you previously shut down by running the following command
on the virtualization host:

```
vagrant up <name of the worker>
```

In the meantime, inside of the commander node, run the following command as
`core` user:

```
watch -n 1 "fleetctl list-machines
```

Once the node is operational you will see something like:

```
MACHINE   IP    METADATA
0bedb413... worker-big-1  size=big
835b610b... worker-1  size=small
f5b7bd07... worker-2  size=small
```

Now execute the `fleetctl list-units` command. As you will notice there is still
one instance of the `guestbook-http@1`service, which is still running on the
same worker node.

We can start a new instance by doing: `fleetctl start guesbook-http@2.service`.

The new instance should start immediately since the Docker image has already
been downloaded on the worker node:

```
$ fleetctl list-units
UNIT        MACHINE       ACTIVE  SUB
guestbook-http@1.service  f5b7bd07.../worker-2    active  running
guestbook-http@2.service  835b610b.../worker-1    active  running
mongodb-discovery.service 0bedb413.../worker-big-1  active  running
mongodb.service     0bedb413.../worker-big-1  active  running
```

The nginx process will now direct http requests either to the `guestbook-http@1`
or to the `guestbook-http@2` service. You can also shut down one of the nodes
without incurring into downtimes of the web application: nginx will realize one
of the nodes is unreachable and will redirect all the requests to the working
one.

# Further experiments

One possible exercise is to make the MongoDB database persistent. This can be
done in different ways:
  * Use the "data-only container pattern" (see [data volumes](https://docs.docker.com/userguide/dockervolumes/#adding-a-data-volume)).
  * [Mount a host directory as a data volume](https://docs.docker.com/userguide/dockervolumes/#mount-a-host-directory-as-a-data-volume).
  * ... the sky is the limit ... :)

You could also create a MongoDB's [replica sets](http://docs.mongodb.org/manual/replication/)
by running new MongoDB instances on new workers. That would eliminate the single
point of failure of the web application: the single instance of MongoDB.

