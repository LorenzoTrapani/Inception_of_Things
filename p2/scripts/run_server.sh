#!/bin/bash

# Installa K3s in modalità server sulla VM con IP fisso 192.168.56.110.
# Viene chiamato dal Vagrantfile come provisioner sulla macchina loreS.

# Rileva l'interfaccia di rete che ha l'IP 192.168.56.110 (rete host-only).
# Serve per passare --flannel-iface a K3s, altrimenti flannel potrebbe
# usare l'interfaccia sbagliata (es. eth0 con l'IP NAT di Vagrant).
IFACE=$(ip -4 addr show | grep "192.168.56.110" | awk '{print $NF}')

if [ -z "$IFACE" ]; then
  echo "Interface with IP 192.168.56.110 not found, using default"
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --write-kubeconfig-mode=644" sh -
else
  echo "Using interface: $IFACE"
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --flannel-iface=$IFACE --write-kubeconfig-mode=644" sh -
fi

# Copia il kubeconfig generato da K3s nella home di vagrant
# così l'utente vagrant può usare kubectl senza sudo.
sudo mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config

# Questo replace serve perché k3s.yaml punta a 127.0.0.1 di default,
# ma dall'esterno della VM bisogna usare l'IP host-only reale.
sudo sed -i 's/127.0.0.1/192.168.56.110/g' /home/vagrant/.kube/config

sudo chown -R vagrant:vagrant /home/vagrant/.kube

echo "K3s server ready, starting to deploy apps"
