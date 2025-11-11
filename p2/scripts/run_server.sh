#!/bin/bash

IFACE=$(ip -4 addr show | grep "192.168.56.110" | awk '{print $NF}')

if [ -z "$IFACE" ]; then
  echo "Interface with IP 192.168.56.110 not found, using default"
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --write-kubeconfig-mode=644" sh -
else
  echo "Using interface: $IFACE"
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --flannel-iface=$IFACE --write-kubeconfig-mode=644" sh -
fi

sudo mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo sed -i 's/127.0.0.1/192.168.56.110/g'
sudo chown -R vagrant:vagrant /home/vagrant/.kube

echo "K3s server ready, starting to deploy apps"