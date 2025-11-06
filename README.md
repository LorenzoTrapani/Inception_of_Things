
# Inception of Things

A hands-on exploration of Kubernetes infrastructure using K3s, K3d, Vagrant, and GitOps.
This repository contains three progressive projects that demonstrate **Kubernetes cluster setup, application deployment, and continuous deployment.**

### Requirements

- Vagrant
- VirtualBox
- 2GB+ available RAM

## P1: K3s and Vagrant

Sets up a multi-node Kubernetes cluster from scratch using K3s and Vagrant. This project involves:
- Creating two VMs with static IPs on a private network
- Installing K3s on the controller node `(lotrapanS at 192.168.56.110)`
- Joining a worker node `(lotrapanSW at 192.168.56.111)` to the cluster
- Automatic token sharing between nodes via Vagrant's shared folder
- Network interface detection for Flannel CNI configuration

The setup scripts handle everything: K3s installation, kubeconfig generation, and kubectl configuration for both nodes.

**Try it:**
```bash
cd p1
vagrant up
vagrant ssh lotrapanS  # or vagrant ssh lotrapanSW
kubectl get nodes -o wide
```

## P2: K3s and Three Simple Applications

Deploys three web applications on a single-node K3s cluster with ingress routing. This project involves:
- Single-node K3s cluster setup
- Kubernetes Deployments and Services
- Ingress controller for host-based routing
- Replica scaling (app2 runs 3 replicas)

Applications:
- **app1**: accessible via `app1.com`
- **app2**: accessible via `app2.com` (3 replicas)
- **app3**: default route (accessible via IP)

**Try it:**
```bash
cd p2
vagrant up

# Add to your /etc/hosts:
192.168.56.110 app1.com app2.com

# Test with curl:
curl -H "Host: app1.com" 192.168.56.110
curl -H "Host: app2.com" 192.168.56.110
curl 192.168.56.110  # app3 (default)
```

All applications use the same Flask container image (`lotrapan/flask-app:18`) but are routed differently based on the hostname.

## P3: K3d and Argo CD

Coming soon - GitOps continuous deployment with K3d and Argo CD.
