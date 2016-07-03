# -*- mode: ruby -*-
# vi: set ft=ruby :

servers=[
     {
       :hostname => "cni-master1",
       :ip1 => "192.168.10.10",
       :ip2 => "192.168.99.10",
       :box => "puppetlabs/ubuntu-16.04-64-nocm",
       :ram => 6192,
       :cpu => 4
     },
     {
       :hostname => "cni-worker1",
       :ip1 => "192.168.10.21",
       :ip2 => "192.168.99.21",
       :box => "puppetlabs/ubuntu-16.04-64-nocm",
       :ram => 6192,
       :cpu => 4
     },
     {
       :hostname => "cni-worker2",
       :ip1 => "192.168.10.22",
       :ip2 => "192.168.99.22",
       :box => "puppetlabs/ubuntu-16.04-64-nocm",
       :ram => 6192,
       :cpu => 4
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
          node.vm.network "private_network", ip: machine[:ip1]
          node.vm.network "private_network", ip: machine[:ip2]
#            virtualbox__intnet: "cni-dev-bridge"
          #node.vm.network "private_network", type: "dhcp",
          #  nic_type: "virtio"
          node.vm.provider "vmware_workstation" do |vws,override|
            vws.vmx["memsize"] = machine[:ram]
            vws.vmx["numvcpus"] = machine[:cpu]
          end
          node.vm.provider "virtualbox" do |vb|
              vb.gui = false
              vb.customize ["modifyvm", :id, "--ioapic", "on"]
              vb.customize ["modifyvm", :id, "--memory", machine[:ram]]
              vb.customize ["modifyvm", :id, "--name", machine[:hostname]]
              vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
          end
          node.vm.provision "shell", path: "vagrant-provision.sh"
        end
  end
end
