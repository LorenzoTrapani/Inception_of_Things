# Design Document - P2: K3s and Three Simple Applications

## Overview

Il progetto P2 implementa un cluster Kubernetes single-node usando K3s su una VM Vagrant. A differenza di P1 (che usa un'architettura multi-node con master e worker), P2 si concentra sul deployment di applicazioni e sul routing HTTP tramite Ingress.

**Architettura generale:**
- 1 VM con K3s in modalità server (no agent nodes)
- 3 Deployments Kubernetes con lo stesso container image
- 3 Services ClusterIP per esporre i deployments
- 1 Ingress resource per gestire il routing basato su hostname
- Traefik come Ingress Controller (incluso di default in K3s)

**Differenze chiave rispetto a P1:**
- Single-node invece di multi-node
- Focus su application deployment invece che su cluster setup
- Uso di Ingress per routing HTTP invece di NodePort/LoadBalancer

## Architecture

### Infrastructure Layer

```
Host Machine (Linux)
    │
    └── VirtualBox
            │
            └── Vagrant VM (lotrapanS)
                    ├── IP: 192.168.56.110
                    ├── OS: Ubuntu 22.04
                    ├── RAM: 1024 MB
                    └── K3s Server
                            ├── Traefik Ingress Controller (porta 80)
                            ├── CoreDNS
                            └── Flannel CNI
```

### Kubernetes Layer

```
K3s Cluster (single-node)
    │
    ├── Namespace: default
    │       │
    │       ├── Deployment: app1 (1 replica)
    │       │       └── Pod: flask-app:18
    │       │
    │       ├── Deployment: app2 (3 replicas)
    │       │       ├── Pod: flask-app:18
    │       │       ├── Pod: flask-app:18
    │       │       └── Pod: flask-app:18
    │       │
    │       └── Deployment: app3 (1 replica)
    │               └── Pod: flask-app:18
    │
    ├── Services
    │       ├── app1-service (ClusterIP) → app1 pods
    │       ├── app2-service (ClusterIP) → app2 pods
    │       └── app3-service (ClusterIP) → app3 pods
    │
    └── Ingress
            ├── Rule: app1.com → app1-service:80
            ├── Rule: app2.com → app2-service:80
            └── Default backend → app3-service:80
```

### Network Flow

```
User Browser
    │
    │ (1) HTTP Request to app1.com
    │
    ├──> /etc/hosts: app1.com → 192.168.56.110
    │
    └──> Vagrant VM:80
            │
            │ (2) Traefik Ingress Controller
            │     - Legge header "Host: app1.com"
            │     - Matcha con Ingress rule
            │
            └──> app1-service (ClusterIP)
                    │
                    └──> app1 Pod (Flask container)
                            │
                            └──> HTTP Response
```

## Components and Interfaces

### 1. Vagrantfile

**Responsabilità:**
- Definire la configurazione della VM
- Configurare la rete privata con IP statico
- Orchestrare il provisioning tramite script

**Configurazione:**
```ruby
- Box: bento/ubuntu-22.04
- Hostname: lotrapanS
- IP: 192.168.56.110
- RAM: 1024 MB
- CPU: 1
- Provisioning: script k3s_server.sh + script deploy_apps.sh
```

**Differenze rispetto a P1:**
- Solo una VM (no multi-machine)
- Due script di provisioning: uno per K3s, uno per le app
- Nessun token sharing necessario

### 2. K3s Installation Script (k3s_server.sh)

**Responsabilità:**
- Installare K3s in modalità server
- Configurare kubectl per l'utente vagrant
- Salvare kubeconfig nella shared folder

**Implementazione:**
```bash
#!/bin/bash

# Detect network interface
IFACE=$(ip -4 addr show | grep "192.168.56.110" | awk '{print $NF}')

# Install K3s server
if [ -z "$IFACE" ]; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --write-kubeconfig-mode=644" sh -
else
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --flannel-iface=$IFACE --write-kubeconfig-mode=644" sh -
fi

# Setup kubectl for vagrant user
sudo mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

# Copy kubeconfig to shared folder
sudo cp /home/vagrant/.kube/config /vagrant/kubeconfig
sudo chmod 644 /vagrant/kubeconfig
```

**Note:**
- Riusa la logica di P1 per il network interface detection
- `--write-kubeconfig-mode=644` permette lettura senza sudo
- No token generation (non serve per single-node)

### 3. Application Deployment Script (deploy_apps.sh)

**Responsabilità:**
- Attendere che K3s sia ready
- Creare i manifests Kubernetes
- Applicare i manifests al cluster

**Implementazione:**
```bash
#!/bin/bash

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
until kubectl get nodes | grep -q "Ready"; do
  sleep 2
done

# Apply manifests
kubectl apply -f /vagrant/manifests/
```

**Note:**
- Usa un loop per attendere che il cluster sia pronto
- Applica tutti i manifests in una directory

### 4. Kubernetes Manifests

#### 4.1 App1 Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  labels:
    app: app1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: flask-app
        image: lotrapan/flask-app:18
        ports:
        - containerPort: 5000
```

**Design decisions:**
- `replicas: 1` come da requirements
- Label `app: app1` per il selector del Service
- Container port 5000 (standard Flask)

#### 4.2 App1 Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app1-service
spec:
  selector:
    app: app1
  ports:
  - protocol: TCP
    port: 80
    targetPort: 5000
  type: ClusterIP
```

**Design decisions:**
- ClusterIP (non serve esposizione esterna diretta)
- Port 80 per l'Ingress, targetPort 5000 per il container
- Selector matcha le label del Deployment

#### 4.3 App2 Deployment e Service

Identico ad App1 ma con:
- `replicas: 3` (requirement 2)
- Labels e selectors con `app: app2`
- Nome `app2` e `app2-service`

#### 4.4 App3 Deployment e Service

Identico ad App1 ma con:
- Labels e selectors con `app: app3`
- Nome `app3` e `app3-service`

#### 4.5 Ingress Resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: apps-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: app1.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
  defaultBackend:
    service:
      name: app3-service
      port:
        number: 80
```

**Design decisions:**
- Due rules per app1.com e app2.com
- `defaultBackend` per app3 (requirement 6)
- Annotation per Traefik (Ingress controller di default in K3s)
- `pathType: Prefix` per matchare tutti i path

## Data Models

### Vagrant Configuration

```ruby
{
  vm: {
    box: "bento/ubuntu-22.04",
    hostname: "lotrapanS",
    network: {
      type: "private_network",
      ip: "192.168.56.110"
    },
    provider: {
      memory: 1024,
      cpus: 1
    },
    provisioners: [
      { type: "shell", path: "scripts/k3s_server.sh" },
      { type: "shell", path: "scripts/deploy_apps.sh" }
    ]
  }
}
```

### Kubernetes Resources

**Deployment:**
```yaml
replicas: int (1 or 3)
selector: map[string]string
template:
  labels: map[string]string
  containers:
    - name: string
      image: string
      ports:
        - containerPort: int
```

**Service:**
```yaml
selector: map[string]string
ports:
  - protocol: string
    port: int (80)
    targetPort: int (5000)
type: ClusterIP
```

**Ingress:**
```yaml
rules:
  - host: string
    http:
      paths:
        - path: string
          pathType: Prefix
          backend:
            service:
              name: string
              port:
                number: int
defaultBackend:
  service:
    name: string
    port:
      number: int
```

## Error Handling

### K3s Installation Failures

**Scenario:** K3s installation script fails
**Handling:**
- Script esce con exit code non-zero
- Vagrant mostra l'errore e ferma il provisioning
- User può fare `vagrant destroy` e riprovare

**Prevention:**
- Usare `-sfL` flags con curl (silent, fail, follow redirects)
- Verificare che l'interfaccia di rete sia disponibile

### Cluster Not Ready

**Scenario:** K3s non diventa ready in tempo
**Handling:**
- Loop di attesa nel deploy_apps.sh
- Timeout implicito (Vagrant ha timeout di provisioning)

**Prevention:**
- Allocare RAM sufficiente (1024 MB)
- Attendere con `until kubectl get nodes | grep Ready`

### Ingress Not Working

**Scenario:** Ingress non instrada correttamente
**Handling:**
- Verificare che Traefik sia running: `kubectl get pods -n kube-system`
- Verificare Ingress resource: `kubectl get ingress`
- Verificare Services: `kubectl get svc`

**Debug commands:**
```bash
kubectl describe ingress apps-ingress
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik
curl -v -H "Host: app1.com" 192.168.56.110
```

### DNS Resolution Issues

**Scenario:** app1.com non risolve
**Handling:**
- Verificare /etc/hosts: `cat /etc/hosts | grep app1.com`
- Aggiungere manualmente: `echo "192.168.56.110 app1.com app2.com" | sudo tee -a /etc/hosts`

**Prevention:**
- Documentare chiaramente nel README
- Fornire comandi copy-paste

### Pod Failures

**Scenario:** Pod non parte o crasha
**Handling:**
- Verificare status: `kubectl get pods`
- Vedere logs: `kubectl logs <pod-name>`
- Descrivere pod: `kubectl describe pod <pod-name>`

**Common issues:**
- Image pull failure: verificare che `lotrapan/flask-app:18` esista
- Resource limits: verificare RAM disponibile

## Testing Strategy

### Manual Testing

**Test 1: Cluster Setup**
```bash
cd p2
vagrant up
vagrant ssh lotrapanS
kubectl get nodes
# Expected: 1 node in Ready state
```

**Test 2: Deployments and Pods**
```bash
kubectl get deployments
# Expected: app1 (1/1), app2 (3/3), app3 (1/1)

kubectl get pods
# Expected: 5 pods total, all Running
```

**Test 3: Services**
```bash
kubectl get svc
# Expected: app1-service, app2-service, app3-service (ClusterIP)
```

**Test 4: Ingress**
```bash
kubectl get ingress
# Expected: apps-ingress with rules for app1.com, app2.com
```

**Test 5: App1 Routing**
```bash
# From host machine (after adding to /etc/hosts)
curl -v http://app1.com
# Expected: HTTP 200, Flask app response

# Or with Host header
curl -H "Host: app1.com" 192.168.56.110
# Expected: HTTP 200, Flask app response
```

**Test 6: App2 Routing and Load Balancing**
```bash
curl -v http://app2.com
# Expected: HTTP 200, Flask app response

# Multiple requests to verify load balancing
for i in {1..10}; do curl -s http://app2.com | grep -o "Pod: .*"; done
# Expected: Requests distributed across 3 pods
```

**Test 7: App3 Default Route**
```bash
curl -v 192.168.56.110
# Expected: HTTP 200, Flask app response (app3)

curl -H "Host: nonexistent.com" 192.168.56.110
# Expected: HTTP 200, Flask app response (app3 as default)
```

**Test 8: Lifecycle Management**
```bash
vagrant halt
vagrant up
vagrant ssh lotrapanS
kubectl get pods
# Expected: All pods running after restart

vagrant destroy -f
# Expected: VM removed cleanly
```

### Validation Checklist

- [ ] VM creata con IP 192.168.56.110
- [ ] K3s installato e running
- [ ] kubectl funzionante
- [ ] 5 pods totali (1 app1, 3 app2, 1 app3)
- [ ] 3 services ClusterIP
- [ ] Ingress resource creato
- [ ] Traefik Ingress Controller running
- [ ] app1.com raggiungibile
- [ ] app2.com raggiungibile con 3 repliche
- [ ] IP diretto raggiunge app3
- [ ] vagrant halt/up funziona
- [ ] vagrant destroy pulisce tutto

## Directory Structure

```
p2/
├── Vagrantfile                 # VM configuration
├── scripts/
│   ├── k3s_server.sh          # K3s installation
│   └── deploy_apps.sh         # Deploy applications
├── manifests/
│   ├── app1-deployment.yaml   # App1 deployment
│   ├── app1-service.yaml      # App1 service
│   ├── app2-deployment.yaml   # App2 deployment (3 replicas)
│   ├── app2-service.yaml      # App2 service
│   ├── app3-deployment.yaml   # App3 deployment
│   ├── app3-service.yaml      # App3 service
│   └── ingress.yaml           # Ingress rules
└── kubeconfig                 # Generated by provisioning
```

## Implementation Notes

### Why Traefik?

K3s include Traefik come Ingress Controller di default. Non serve installare niente, è già pronto all'uso. Traefik:
- Ascolta sulla porta 80 del node
- Legge le Ingress resources automaticamente
- Gestisce il routing basato su hostname
- Supporta defaultBackend

### Why ClusterIP Services?

Non serve esporre i Services direttamente all'esterno perché:
- L'Ingress Controller (Traefik) è già esposto sulla porta 80
- I Services sono accessibili solo dall'interno del cluster
- L'Ingress instrada il traffico ai Services

### Why Single Script for All Apps?

Invece di creare script separati per ogni app, usiamo:
- Un'unica directory `manifests/` con tutti i YAML
- `kubectl apply -f /vagrant/manifests/` applica tutto insieme
- Più semplice da mantenere e modificare

### Provisioning Order

1. Vagrant crea la VM
2. Script `k3s_server.sh` installa K3s
3. Script `deploy_apps.sh` attende che K3s sia ready
4. Script applica tutti i manifests
5. Traefik (già running) legge l'Ingress e configura le routes

### Resource Allocation

1024 MB di RAM sono sufficienti per:
- K3s control plane (~300 MB)
- Traefik (~50 MB)
- 5 Flask pods (~100 MB ciascuno = 500 MB)
- Sistema operativo (~100 MB)
- Totale: ~950 MB (con margine)

Se i pod crashano per OOM, aumentare a 2048 MB nel Vagrantfile.
