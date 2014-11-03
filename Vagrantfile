# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

def create_nodes_pillar(nodes, path)
  File.open(path, 'w') do |file|
    file.write("nodes:\n")
    nodes.each do |node|
      file.write("  - #{node}\n")
    end
  end
end


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # The number of etcd nodes to provision
  num_etcd_nodes = (ENV['NUM_ETCD_NODES'] || 1).to_i

  # The number of worker nodes to provision
  num_worker_nodes = (ENV['NUM_MINIONS'] || 2).to_i

  nodes = ['commander', 'worker-big-1']

  nodes += num_etcd_nodes.times.map {|n| "etcd-#{n+1}"}
  nodes += num_worker_nodes.times.map {|n| "worker-#{n+1}"}


  create_nodes_pillar(nodes,
                      File.join(
                        File.dirname(File.expand_path(__FILE__)),
                        "vagrant", "commander", "pillar", "nodes.sls")
                     )

  # Every Vagrant virtual environment requires a box to build off of.
  BASE_BOX = "flavio/opensuse13-2"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  config.vm.box_check_update = true
  config.vm.provider "virtualbox" do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "512"]
    # Useful when something bad happens
    # vb.gui = true
  end

  config.vm.define "commander" do |config|
    config.vm.box = BASE_BOX
    config.vm.hostname = "commander"
    config.vm.network :private_network, ip: '192.168.1.2', virtualbox__intnet: true
    config.vm.network "forwarded_port", guest: 80, host: 8080
    config.vm.provision "shell", path: "vagrant/setup_private_network"
    config.vm.synced_folder 'vagrant/commander/salt', '/srv/salt'
    config.vm.synced_folder 'vagrant/commander/pillar', '/srv/pillar'
    config.vm.provision "shell", path: "vagrant/provision-commander.sh"
    config.vm.synced_folder 'services', '/home/core/services'
  end

  # etcd node
  num_etcd_nodes.times do |n|
    hostname = "etcd-#{n + 1}"
    config.vm.define hostname do |config|
      config.vm.box = BASE_BOX
      config.vm.hostname = hostname
      config.vm.network :private_network, type: :dhcp, virtualbox__intnet: true
      config.vm.provision "shell", path: "vagrant/setup_private_network"
      config.vm.provision "shell",
                          path: "vagrant/provision-node.sh",
                          args: ['192.168.1.2']
    end
  end

  # worker node
  num_worker_nodes.times do |n|
    hostname = "worker-#{n + 1}"
    config.vm.define hostname do |config|
      config.vm.box = BASE_BOX
      config.vm.hostname = hostname
      config.vm.network :private_network, type: :dhcp, virtualbox__intnet: true
      config.vm.provision "shell", path: "vagrant/setup_private_network"
      config.vm.provision "shell",
                          path: "vagrant/provision-node.sh",
                          args: ['192.168.1.2']
    end
  end

  hostname = "worker-big-1"
  config.vm.define hostname do |config|
    config.vm.box = BASE_BOX
    config.vm.hostname = hostname
    config.vm.network :private_network, type: :dhcp, virtualbox__intnet: true
    config.vm.provision "shell", path: "vagrant/setup_private_network"
    config.vm.provision "shell",
                        path: "vagrant/provision-node.sh",
                        args: ['192.168.1.2']
  end

end

