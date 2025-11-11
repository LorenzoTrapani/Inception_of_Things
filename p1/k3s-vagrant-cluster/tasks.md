# Implementation Plan - P1: K3s and Vagrant Multi-Node Cluster

- [ ] 1. Create project directory structure
  - Create `p1/` directory in the iot workspace
  - Create `p1/scripts/` subdirectory for provisioning scripts
  - _Requirements: 8.4_

- [ ] 2. Implement K3s master installation script
  - [ ] 2.1 Create `scripts/k3s_master.sh` with controller node setup logic
    - Detect network interface for IP 192.168.56.110 using ip command
    - Install K3s in server mode with appropriate flags (--node-ip, --flannel-iface if detected, --write-kubeconfig-mode)
    - Create .kube directory for vagrant user
    - Copy K3s kubeconfig to /home/vagrant/.kube/config
    - Replace 127.0.0.1 with 192.168.56.110 in kubeconfig using sed
    - Set correct ownership for vagrant user
    - Extract node token from /var/lib/rancher/k3s/server/node-token
    - Save token to /vagrant/token for worker access
    - Copy kubeconfig to /vagrant/kubeconfig for worker access
    - Set correct permissions on shared files
    - Make script executable
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 4.5, 6.1, 6.5, 10.1, 10.3, 10.4, 10.5_

- [ ] 3. Implement K3s agent installation script
  - [ ] 3.1 Create `scripts/k3s_agent.sh` with worker node setup logic
    - Accept master IP as first argument ($1)
    - Implement wait loop for /vagrant/token with 300 second timeout
    - Log waiting progress every 5 seconds
    - Exit with error if timeout is reached
    - Read token from /vagrant/token when available
    - Detect network interface for IP 192.168.56.111 using ip command
    - Install K3s in agent mode with appropriate flags (K3S_URL, K3S_TOKEN, --node-ip, --flannel-iface if detected)
    - Create .kube directory for vagrant user
    - Copy kubeconfig from /vagrant/kubeconfig to /home/vagrant/.kube/config
    - Set correct ownership for vagrant user
    - Make script executable
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 6.2, 6.5, 10.2, 10.3, 10.4, 10.5_

- [ ] 4. Create Vagrantfile for multi-machine setup
  - [ ] 4.1 Write Vagrantfile with multi-machine configuration
    - Use Vagrant.configure("2") syntax
    - Add global inline provisioner for both VMs (apt update, install netcat-openbsd, setup /etc/hosts)
    - Configure /etc/hosts with both node entries (192.168.56.110 lotrapanS, 192.168.56.111 lotrapanSW)
    - Set base box to bento/ubuntu-22.04 globally
    - Define controller node (lotrapanS) with config.vm.define
    - Set controller hostname to "lotrapanS"
    - Configure controller private network with IP 192.168.56.110
    - Add controller provisioner for scripts/k3s_master.sh
    - Configure controller VirtualBox provider with 1024 MB RAM and 1 CPU
    - Define worker node (lotrapanSW) with config.vm.define
    - Set worker hostname to "lotrapanSW"
    - Configure worker private network with IP 192.168.56.111
    - Add worker provisioner for scripts/k3s_agent.sh with master IP argument
    - Configure worker VirtualBox provider with 1024 MB RAM and 1 CPU
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 8.4, 9.1, 9.2, 9.3, 9.4_

- [ ] 5. Verify the complete setup
  - [ ] 5.1 Test VM creation and provisioning
    - Run `vagrant up` in p1 directory
    - Verify both VMs are created successfully
    - Check vagrant status shows both VMs running
    - Verify no provisioning errors in output
    - _Requirements: 1.1, 1.5_
  
  - [ ] 5.2 Test network configuration
    - SSH into controller node
    - Verify IP 192.168.56.110 is assigned to correct interface
    - Test ping to worker node using hostname (ping lotrapanSW)
    - Verify /etc/hosts contains both node entries
    - SSH into worker node
    - Verify IP 192.168.56.111 is assigned to correct interface
    - Test ping to controller node using hostname (ping lotrapanS)
    - Verify /etc/hosts contains both node entries
    - _Requirements: 1.2, 1.3, 1.4, 9.1, 9.2, 9.3, 9.4, 9.5_
  
  - [ ] 5.3 Test K3s installation on controller
    - SSH into controller node
    - Check K3s service status with systemctl
    - Verify K3s service is active and running
    - Run kubectl get nodes and verify controller node is Ready
    - Check node has control-plane,master role
    - Verify kubectl version shows both client and server
    - _Requirements: 3.1, 3.4, 3.5, 6.1, 7.2_
  
  - [ ] 5.4 Test token generation and sharing
    - SSH into controller node
    - Verify /vagrant/token file exists and is readable
    - Check token format matches K10...:server:... pattern
    - Verify /vagrant/kubeconfig file exists and is readable
    - Check kubeconfig contains server URL with 192.168.56.110 (not 127.0.0.1)
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [ ] 5.5 Test K3s installation on worker
    - SSH into worker node
    - Check K3s agent service status with systemctl
    - Verify K3s agent service is active and running
    - Run kubectl get nodes and verify both nodes are listed
    - _Requirements: 5.3, 5.4, 5.5, 6.2_
  
  - [ ] 5.6 Test cluster status and functionality
    - SSH into controller node
    - Run kubectl get nodes -o wide
    - Verify both nodes show Ready status
    - Verify controller has control-plane,master role
    - Verify worker has <none> or worker role
    - Verify internal IPs are correct (192.168.56.110 and 192.168.56.111)
    - Check system pods with kubectl get pods -n kube-system
    - Verify all system pods are Running (coredns, flannel, metrics-server, traefik)
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [ ] 5.7 Test kubectl from worker node
    - SSH into worker node
    - Run kubectl get nodes and verify both nodes are listed
    - Run kubectl get pods -A and verify all system pods are visible
    - Verify kubectl commands work without sudo
    - _Requirements: 6.2, 6.3, 6.4, 6.5_
  
  - [ ] 5.8 Test pod scheduling across nodes
    - SSH into controller node
    - Create test deployment: kubectl create deployment nginx --image=nginx --replicas=2
    - Wait for pods to be ready
    - Run kubectl get pods -o wide
    - Verify pods are scheduled on both nodes
    - Delete test deployment: kubectl delete deployment nginx
    - _Requirements: 7.1_
  
  - [ ] 5.9 Test network interface detection
    - SSH into controller node
    - Check K3s logs for interface detection: sudo journalctl -u k3s | grep -i interface
    - Verify Flannel interface exists: ip addr show | grep flannel
    - SSH into worker node
    - Check K3s agent logs for interface detection: sudo journalctl -u k3s-agent | grep -i interface
    - Verify Flannel interface exists: ip addr show | grep flannel
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_
  
  - [ ] 5.10 Test VM lifecycle management
    - Run vagrant halt to stop both VMs
    - Verify vagrant status shows both VMs stopped
    - Run vagrant up to restart VMs
    - SSH into controller and verify cluster still works (kubectl get nodes)
    - Verify both nodes are Ready after restart
    - Run vagrant destroy -f to remove VMs
    - Verify vagrant status shows VMs not created
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_
