#!/bin/bash

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[38;5;208m'
RESET='\033[0m'

# SETUP Cluster

echo -e "${BLUE}=== Setup cluster K3d ===${RESET}"

CLUSTER_NAME="lotrapanCluster"
ARGOCD_NAMESPACE="argocd"
ARGOCD_VERSION="v2.14.2"

if ! k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
    echo -e "${ORANGE}Creating K3d cluster: $CLUSTER_NAME...${RESET}"
    k3d cluster create "$CLUSTER_NAME" -p 8888:30420 -p 8046:30046
    echo -e "${GREEN}Cluster '$CLUSTER_NAME' created${RESET}"
else
    echo -e "${GREEN}Cluster '$CLUSTER_NAME' already exists${RESET}"
fi

mkdir -p "$HOME/.kube"
k3d kubeconfig merge "$CLUSTER_NAME" --kubeconfig-switch-context -o "$HOME/.kube/config"
echo -e "${GREEN}kubeconfig saved to $HOME/.kube/config${RESET}"

echo -e "${ORANGE}Creating namespaces...${RESET}"
for NS in argocd dev; do
    if ! kubectl get namespace "$NS" &>/dev/null; then
        kubectl create namespace "$NS"
    fi
done

echo -e "${GREEN}Namespaces ready${RESET}"

echo -e "${BLUE}=== Cluster ready ===${RESET}"

# SETUP ArgoCD

if ! kubectl get deployment argocd-server -n "$ARGOCD_NAMESPACE" &>/dev/null; then
    echo -e "${ORANGE}Installing ArgoCD in namespace '$ARGOCD_NAMESPACE'...${RESET}"

    kubectl apply -n "$ARGOCD_NAMESPACE" \
        --server-side \
        -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
fi

# eseguito sempre: aspetta che i pod siano pronti
echo -e "${ORANGE}Waiting for ArgoCD pods to be ready...${RESET}"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n "$ARGOCD_NAMESPACE" --timeout=300s
echo -e "${GREEN}ArgoCD pods ready${RESET}"

CURRENT_TYPE=$(kubectl get svc argocd-server -n "$ARGOCD_NAMESPACE" -o jsonpath='{.spec.type}')

if ! [ "$CURRENT_TYPE" = "NodePort" ]; then
    kubectl patch svc argocd-server -n "$ARGOCD_NAMESPACE" -p \
        '{"spec": {"type": "NodePort", "ports": [{"port": 443, "nodePort": 30420}]}}'
fi

echo -e "${GREEN}ArgoCD server exposed on NodePort 30420 (localhost:8888)${RESET}"

# get admin password

echo -e "${ORANGE}Retrieving ArgoCD admin password...${RESET}"

PASSWORD=$(kubectl get secret argocd-initial-admin-secret \
    -n "$ARGOCD_NAMESPACE" \
    -o jsonpath="{.data.password}" | base64 -d)

echo -e "${ORANGE}Logging into ArgoCD...${RESET}"
for i in $(seq 1 10); do
    argocd login localhost:8888 --insecure --username admin --password "$PASSWORD" 2>/dev/null && break
    echo -e "${ORANGE}Waiting for ArgoCD gRPC... ($i/10)${RESET}"
    sleep 5
done

echo -e "${BLUE}=== ArgoCD ready ===${RESET}"
echo -e "UI:       https://localhost:8888"
echo -e "user:     admin"
echo -e "password: ${PASSWORD}"



