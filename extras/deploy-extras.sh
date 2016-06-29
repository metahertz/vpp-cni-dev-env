#!/bin/sh

# Deploy the Kubernetes UI and DNS service onto our Dev Cluster
kubectl create -f /vagrant/extras/manifests/kube-ui.manifest
kubectl create -f /vagrant/extras/manifests/kube-dns.manifest
