#!/bin/bash

echo "Waiting for K3s cluster to be ready..."

TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  NODE_STATUS=$(kubectl get nodes --no-headers 2>/dev/null | awk '{print $2}')

  if [ "$NODE_STATUS" = "Ready" ]; then
    echo "K3s cluster is ready!"
    break
  fi

  echo "Waiting for node to be ready... ($ELAPSED/$TIMEOUT seconds)"
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "ERROR: Timeout waiting for K3s cluster to be ready"
  exit 1
fi

# Crea il namespace "apps" dove vivranno tutte e 3 le applicazioni.
# Isola le risorse dal namespace default.
echo "Creating apps namespace..."
kubectl create namespace apps

# Imposta "apps" come namespace di default per il contesto corrente,
# così i comandi kubectl successivi non richiedono -n apps esplicito.
echo "Switching to apps namespace..."
kubectl config set-context --current --namespace=apps

echo "Deploying applications and ingress..."
kubectl apply -f /vagrant/conf/app1.yaml -n apps
kubectl apply -f /vagrant/conf/app2.yaml -n apps
kubectl apply -f /vagrant/conf/app3.yaml -n apps
kubectl apply -f /vagrant/conf/ingress.yaml -n apps

echo "Done! Checking deployment status..."
