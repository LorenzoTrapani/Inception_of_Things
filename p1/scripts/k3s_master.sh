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
sudo sed -i 's/127.0.0.1/192.168.56.110/g' /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo $K3S_TOKEN > /vagrant/token

sudo cp /home/vagrant/.kube/config /vagrant/kubeconfig
sudo chmod 644 /vagrant/kubeconfig

echo "K3s server ready, token and kubeconfig saved"