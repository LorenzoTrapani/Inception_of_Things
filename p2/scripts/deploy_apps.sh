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

echo "Creating apps namespace..."
kubectl create namespace apps

echo "Switching to apps namespace..."
kubectl config set-context --current --namespace=apps

echo "Deploying applications and ingress..."
kubectl apply -f /vagrant/confs/app1.yaml -n apps
kubectl apply -f /vagrant/confs/app2.yaml -n apps
kubectl apply -f /vagrant/confs/app3.yaml -n apps
kubectl apply -f /vagrant/confs/ingress.yaml -n apps

echo "Done! Checking deployment status..."
