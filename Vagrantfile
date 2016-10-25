# -*- mode: ruby -*-
# vi: set ft=ruby :

servers=[
     {
       :hostname => "cni-master1",
       :ip => "192.168.10.10",
       :box => "ubuntu/xenial64",
       :ram => 2048,
       :cpu => 2
     },
     {
       :hostname => "cni-worker1",
       :ip => "192.168.10.21",
       :box => "ubuntu/xenial64",
       :ram => 4096,
       :cpu => 2
     },
     {
       :hostname => "cni-worker2",
       :ip => "192.168.10.22",
       :box => "ubuntu/xenial64",
       :ram => 4096,
       :cpu => 2
     }
   ]


Vagrant.configure(2) do |config|
  servers.each do |machine|
      name = machine[:hostname]
      config.vm.define machine[:hostname] do |node|
          node.vm.box = machine[:box]
          node.vm.hostname = machine[:hostname]
          config.vm.synced_folder ".", "/vagrant"
          config.vm.synced_folder "./ipam-db", "/var/lib/cni/networks"
          node.vm.network "private_network", ip: machine[:ip],
            virtualbox__intnet: "cni-dev-bridge"
          node.vm.network "private_network", type: "dhcp",
            nic_type: "82540EM",
            virtualbox__intnet: "cni-dev-bridge"
          node.vm.provider "virtualbox" do |vb|
              vb.gui = false
              vb.customize ["modifyvm", :id, "--memory", machine[:ram]]
              vb.customize ["modifyvm", :id, "--name", machine[:hostname]]
              vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
              vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
              vb.customize ['modifyvm', :id, '--cableconnected3', 'off']
          end
          node.vm.provision "shell", path: "vagrant-provision.sh"
        end
  end
end
