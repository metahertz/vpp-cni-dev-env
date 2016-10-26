# What
This repository sets up a three node kubernetes cluster with Calico CNI and VPP Pre-Compiled.
Ideal for VPP & CNI Development.
The deployment should be as simple as ```vagrant up```.

### Specifics
* Kubernetes 1.3.0-beta.2
* Ubuntu 16.04 LTS
* Containerized Kubernetes master Components
* SystemD for other components

# Prerequisites
- Vagrant version 1.8.4 or above due to bugs predictable udev interface names in older versions.
- Git (to clone the repo)
- Virtualbox with the Extensions pack installed. (My env is MacOSX).

# To use

```
git clone git@github.com:matjohn2/vpp-cni-dev-env.git
cd vpp-cni-dev-env
vagrant plugin install vagrant-vbguest #THIS IS IMPORTANT. The ubuntu images don't have the Virtualbox tools installed.
vagrant up
```

Once the cluster is up. You can access kubectl directly from the master node.

```
vagrant ssh cni-master1
$ kubectl get po
$ kubectl --namespace kube-system get po
```

You can also deploy the Kubernetes UI as an application (installs the kubernetes DNS service too).
```
vagrant ssh cni-master1
/vagrant/extras/deploy-extras.sh
```

Internet speeds may affect the time taken to see active applications in the ``` kubectl get po ``` commands initially, as docker images download into a new cluster.


# VPP Demo
VPP and the FIBv2 compatible Calico-Felix have been compiled and installed.
VPP will be running and have claimed the GigE0/9/0 Interface.
If not you may need to "attach" it in VirtualBox network settings (NIC Number 3, tick 'cable connected') and then perform the following on the VM via ``` vagrant ssh cni-workerX ``` ;

```
# After ensuring 'cable connected' is ticked in VirtualBOX settings
sudo ifconfig enp0s9 down
sudo systemctl restart vpp.service
sudo vppctl sh int
```

Then you can simply start Calico-Felix on *BOTH* worker nodes as follows:

```
sudo FELIX_ETCDADDR=192.168.10.21:4001 FELIX_LOGSEVERITYSCREEN=DEBUG calico-felix
```

Addresses are all pre-configured to work with this environment.

Felix will initially be in a 'waiting for etcD' state. to enable. perform the following commands on *cni-worker1* :

```
calicoctl profile add calico
calicoctl pool add 192.168.0.0/16 --ipip --nat-outgoing
etcdctl set /calico/v1/Ready true
```

Felix will then be running and through Calico-CNI (pre installed in this K8's Cluster) all new containers should be networked via VPP.

on the ```CNI-Master1``` node you can ```kubectl run nginxdeployment1 --image=nginx``` and then perform a ```kubectl get po``` to track the deployment. Once deployed, you should see new ```host-caliXYZ``` interfaces in VPP.

The demo calio-vpp-route-agent is also pre-installed on each worker node in /home/ubuntu.
Once you have workloads in Calico, you can run the agent:

```
# On CNI-Worker1
cd /home/ubuntu/vpp-calico-route-agent
sudo python -i agent.py "calico/ipam/v2/assignment/ipv4/block" 1 172.16.0.1 24 http 192.168.10.21

# on CNI-Worker2
cd /home/ubuntu/vpp-calico-route-agent
sudo python -i agent.py "calico/ipam/v2/assignment/ipv4/block" 1 172.16.0.2 24 http 192.168.10.21
```

You will see the commands are similar, but we also tell the agent what IP address to configure our VPP UPLINK (GigabitEthernet0/9/0 (VPP SWIF index 1)) and where to reach our Calico ETCD DB.

If the agent produces an error finding etcd records/tree; then create a workload first. The first calico workload causes the ETCD ``` calico/ipam/* ``` subtree to be created in ETCD and we need this first.


# Expectations

### Upto Commit 30b7be923c4eb716eace7b0105c6996f36dd292d
The vagrant tooling will set you up three nodes as per the diagram below.

![CNI Kubernetes Environment](/diagrams/Vagrant-Ubuntu-CNI-VPP-Dev-Env-Arch-v1.png)

IP addresses are static. The example CNI setup is configured to assign 192.168.10.100 - 192.168.10.200 to containers via the IPVLAN CNI Plugin (Using the existing host 192.168.10.0/24 interface to enable node to node container reachability).

Services will also be exposed on 192.168.10.224/27 (ie 192.168.10.224 - 192.168.10.255)... You see where we're going with this. *EVERYTHING* the cluster does or needs an IP for, should be within the 192.168.10.0/24 network, available to each node as a shared network (interface enp0s8 on each host).

Even the cluster workers talk to master via it's IP: ```192.168.10.10```. The other interface on the nodes is just a virtualbox NAT for default gateway/internet connectivity.

The Kubernetes version deployed is: v1.3.0

### After Commit 30b7be923c4eb716eace7b0105c6996f36dd292d (MASTER)
The default CNI configuration was changed to provide a VPP & Calico development environment. (Versus a static demo CNI Environment as explained above).

Therefore now the provisioning scripts also do the following:

    - Configure extra interfaces and more RAM in the Vagrant file.
    - Apt-get more dependancies for the VPP and Calico build process.
    - Git clone, configure and compile VPP and Calico-Felix with VPP Patches.
    - Git clone a demo VPP-Calico multi-host routing agent.
    - Configure Kubernetes to use the calico-cni plugin.
    - Installs the calico-cni binaries by default.



# Developing CNI
To change the CNI configuration for a cluster, you need only look in one place ``` ./cni ```.
All contents of ```conf``` will be placed in the correct ```/etc/cni/net.d/``` location.
All binaries in ```bin``` will be placed into ```/opt/cni/bin```.

Therefore, to use a new CNI plugin. Simply place your CNI configuration and CNI binaries into ```../cni/``` and redploy the cluster:

```
$ vagrant destroy -f
$ vagrant up
```

The kubelet is already configured to always use CNI.

## More complex CNI usecases.
More complex CNI configurations may require pre-requisites installed during the VM creation. To this end. Cluster bring-up is done in a single file ```~/.vagrant-provision.sh```.

The master can be left alone (it's a master only, no developers containers will ever be spun up there). So the worker configuration (starting at line 77) will be where you want to add any low level dependancies.

## Not rebuilding the cluster.
If you want to hack without re-building each time, then the workers are very simple. The below info should get you started.

### kubelet
The only process we really care about directly on the worker hosts are the kubelet. These are the remote agents that make a kubernes worker do anything.

They authenticate with the master via SSL certs (already setup by the vagrant provisioning script) and the kubelet config itself (Ie, how it knows to use CNI) is in the SystemD configuration file at ```/etc/systemd/kubelet.service```.

### CNI
There isn't much in the kubelet configuration for CNI, apart from 'Use CNI'. This is because the CNI is designed to look in ```/etc/cni/net.d``` for configuration files, these should be named after a binary in ```/opt/cni/bin/``` and therefore the kubelet in CNI mode will follow that process to find out which CNI plugin binaries to use.

If you do want to change the binaries/configuration files for CNI, you'll likley want to restart the kubelet:

$ ```sudo systemctl restart kubelet.service ```
$ ```sudo systemctl status kubelet.service ```

##Old CNI setup (upto commit 30b7be923c4eb716eace7b0105c6996f36dd292d. See above)
The out of the box CNI setup uses the standard 'ipvlan' plugin and 'local-host' IPAM plugin. Together they do two things.
1. Connects each container to a 'subinterface' of the hosts enp0s8 NIC. (Sharing the NIC's MAC).
2. Picks an IP from the 192.168.10.100 - 192.168.10.200 range. And saves this into ```/var/lib/cni/networks/cnidemo/``` as rudimentaty lease management.

The path ```/var/lib/cni/networks/``` is shared by our vagrant setup, so hosts wont use conflicting IP's on the subnets for their containers.

Configuration of the IP range and master interface above will be self explanitary when browsing ```./cni/conf/ipvlan.conf```
More information on the plugins can be found here:

- IPVLAN: goo.gl/Luafaw
- HOST-LOCAL: goo.gl/y6ePtK

# Notes
- Logging on each worker node (for the kubelet) can be found at ``` journalctl -ru kubelet.service ``` (<3 SystemD)
- A kubelet error about CNI and the status of ETH0 can be safley ingored. See: https://github.com/projectcalico/calico-containers/issues/952
