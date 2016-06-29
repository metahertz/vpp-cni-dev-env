# What
This repository sets up a three node kubernetes cluster with basic CNI. Ideal for CNI Development.
The deployment should be as simple as ```vagrant up```.

### Specifics
* Kubernetes 1.3.0-beta.2
* Ubuntu 16.04 LTS
* Containerized Kubernetes master Components
* SystemD for other components

# Prerequisites
- Vagrant version 1.8.4 or above due to bugs predictable udev interface names in older versions.
- Git (to clone the repo)
- Virtualbox with the Extensions pack installed.

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

Internet speeds may affect the time taken to see active applications in the ``` kubectl get po ``` commands.

# Expectations

The vagrant tooling will set you up three nodes as per the diagram below.

![CNI Kubernetes Environment](/diagrams/Vagrant-Ubuntu-CNI-VPP-Dev-Env-Arch-v1.png)

IP addresses are static. The example CNI setup is configured to assign 192.168.10.100 - 192.168.10.200 to containers via the IPVLAN CNI Plugin (Using the existing host 192.168.10.0/24 interface to enable node to node container reachability).

Services will also be exposed on 192.168.10.224/27 (ie 192.168.10.224 - 192.168.10.255)... You see where we're going with this. *EVERYTHING* the cluster does or needs an IP for, should be within the 192.168.10.0/24 network, available to each node as a shared network (interface enp0s8 on each host).

Even the cluster workers talk to master via it's IP: ```192.168.10.10```. The other interface on the nodes is just a virtualbox NAT for default gateway/internet connectivity.

The Kubernetes version deployed is: v1.3.0-beta.2.


# Notes
- Logging on each worker node (for the kubelet) can be found at ``` journalctl -ru kubelet.service ``` (<3 SystemD)
- A kubelet error about CNI and the status of ETH0 can be safley ingored. See: https://github.com/projectcalico/calico-containers/issues/952

## Why 1.3.0-beta.2?
Older versions DO NOT play nicely with CNI plugins due to passing extra ARGS without also passsing ```CNI_ARGS=IgnoreUnknown=1``` for general reading on this, see here: https://github.com/containernetworking/cni/pull/158

Luckily, K8's 1.3.0 is due to be released any day now!
