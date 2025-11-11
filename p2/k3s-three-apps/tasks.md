# Implementation Plan - P2: K3s and Three Simple Applications

- [ ] 1. Create project directory structure
  - Create `p2/` directory in the iot workspace
  - Create `p2/scripts/` subdirectory for provisioning scripts
  - Create `p2/conf/` subdirectory for Kubernetes YAML files
  - _Requirements: 7.4_

- [ ] 2. Implement K3s server installation script
  - [ ] 2.1 Create `scripts/k3s_server.sh` with K3s installation logic
    - Detect network interface for IP 192.168.56.110
    - Install K3s in server mode with correct flags (--node-ip, --flannel-iface, --write-kubeconfig-mode)
    - Setup kubectl configuration for vagrant user
    - Copy kubeconfig to shared folder for host access
    - Make script executable
    - _Requirements: 1.2, 1.3, 1.5_

- [ ] 3. Implement application deployment script
  - [ ] 3.1 Create `scripts/deploy_apps.sh` with deployment logic
    - Wait for K3s cluster to be in Ready state
    - Apply all Kubernetes manifests from /vagrant/manifests/ directory
    - Make script executable
    - _Requirements: 2.4, 3.4_

- [ ] 4. Create Kubernetes manifests for App1
  - [ ] 4.1 Create `manifests/app1-deployment.yaml`
    - Define Deployment with 1 replica
    - Use image lotrapan/flask-app:18
    - Set container port 5000
    - Add labels for Service selector (app: app1)
    - _Requirements: 2.1, 2.4_
  
  - [ ] 4.2 Create `manifests/app1-service.yaml`
    - Define Service of type ClusterIP
    - Selector matches app1 Deployment labels
    - Port 80 mapping to targetPort 5000
    - _Requirements: 3.1, 3.4_

- [ ] 5. Create Kubernetes manifests for App2
  - [ ] 5.1 Create `manifests/app2-deployment.yaml`
    - Define Deployment with 3 replicas
    - Use image lotrapan/flask-app:18
    - Set container port 5000
    - Add labels for Service selector (app: app2)
    - _Requirements: 2.2, 2.5_
  
  - [ ] 5.2 Create `manifests/app2-service.yaml`
    - Define Service of type ClusterIP
    - Selector matches app2 Deployment labels
    - Port 80 mapping to targetPort 5000
    - Service will load balance across 3 replicas
    - _Requirements: 3.2, 3.5, 5.2_

- [ ] 6. Create Kubernetes manifests for App3
  - [ ] 6.1 Create `manifests/app3-deployment.yaml`
    - Define Deployment with 1 replica
    - Use image lotrapan/flask-app:18
    - Set container port 5000
    - Add labels for Service selector (app: app3)
    - _Requirements: 2.3, 2.4_
  
  - [ ] 6.2 Create `manifests/app3-service.yaml`
    - Define Service of type ClusterIP
    - Selector matches app3 Deployment labels
    - Port 80 mapping to targetPort 5000
    - _Requirements: 3.3, 3.4_

- [ ] 7. Create Ingress manifest for routing
  - [ ] 7.1 Create `manifests/ingress.yaml`
    - Define Ingress resource with Traefik annotations
    - Add rule for app1.com routing to app1-service
    - Add rule for app2.com routing to app2-service
    - Set defaultBackend to app3-service for IP-only access
    - Configure all paths with pathType: Prefix
    - _Requirements: 4.1, 4.4, 5.1, 6.1, 6.2, 6.4_

- [ ] 8. Create Vagrantfile for single-node setup
  - [ ] 8.1 Write Vagrantfile configuration
    - Use bento/ubuntu-22.04 box
    - Set hostname to lotrapanS
    - Configure private network with IP 192.168.56.110
    - Set VirtualBox provider with 1024 MB RAM and 1 CPU
    - Add provisioner for scripts/k3s_server.sh
    - Add provisioner for scripts/deploy_apps.sh
    - Add initial shell provisioner for system updates
    - _Requirements: 1.1, 1.4, 7.1, 7.2, 7.3, 7.4_

- [ ] 9. Verify the complete setup
  - [ ] 9.1 Test VM creation and K3s installation
    - Run `vagrant up` in p2 directory
    - SSH into VM and verify K3s node is Ready
    - Check that kubectl is configured correctly
    - _Requirements: 1.1, 1.3, 1.5_
  
  - [ ] 9.2 Test deployments and pods
    - Verify all 5 pods are running (1 app1, 3 app2, 1 app3)
    - Check deployment replica counts match requirements
    - _Requirements: 2.1, 2.2, 2.3, 2.5_
  
  - [ ] 9.3 Test services
    - Verify all three ClusterIP services exist
    - Check service selectors match deployment labels
    - _Requirements: 3.1, 3.2, 3.3_
  
  - [ ] 9.4 Test Ingress routing for app1
    - Add "192.168.56.110 app1.com" to host /etc/hosts
    - Test with curl using Host header: `curl -H "Host: app1.com" 192.168.56.110`
    - Verify HTTP 200 response from Flask app
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [ ] 9.5 Test Ingress routing for app2
    - Add "192.168.56.110 app2.com" to host /etc/hosts
    - Test with curl using Host header: `curl -H "Host: app2.com" 192.168.56.110`
    - Verify HTTP 200 response from Flask app
    - Make multiple requests to verify load balancing across 3 replicas
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  
  - [ ] 9.6 Test default route for app3
    - Test with curl to IP only: `curl 192.168.56.110`
    - Verify HTTP 200 response from Flask app (app3)
    - Test with non-matching hostname to verify default backend
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  
  - [ ] 9.7 Test VM lifecycle management
    - Test `vagrant halt` stops the VM correctly
    - Test `vagrant up` restarts with K3s intact
    - Test `vagrant destroy` removes VM completely
    - _Requirements: 7.1, 7.2, 7.3_
