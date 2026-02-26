#!/bin/bash

MASTER_IP="192.168.56.110"

# Remove stale artifacts from previous runs so the worker doesn't pick them up early
rm -f /vagrant/token /vagrant/kubeconfig

IFACE=$(ip -br -4 addr show | grep "$MASTER_IP" | awk '{print $1}')

if [ -z "$IFACE" ]; then
  echo "Interface with IP $MASTER_IP not found, using default"
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=$MASTER_IP --write-kubeconfig-mode=644" sh -
else
  echo "Using interface: $IFACE"
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=$MASTER_IP --flannel-iface=$IFACE --write-kubeconfig-mode=644" sh -
fi

while ! systemctl is-active --quiet k3s; do
  echo "Waiting for k3s to be active..."
  sleep 3
done

mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sed -i "s/127.0.0.1/$MASTER_IP/g" /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
echo $K3S_TOKEN > /vagrant/token

cp /home/vagrant/.kube/config /vagrant/kubeconfig
chmod 644 /vagrant/kubeconfig

echo "Token and kubeconfig saved"
echo "K3s server ready"

