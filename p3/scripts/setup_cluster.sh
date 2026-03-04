#!/bin/bash

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[38;5;208m'
RESET='\033[0m'

CLUSTER_NAME="lotrapanCluster"
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

create_cluster() {
    if k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
        echo -e "${GREEN}Cluster '$CLUSTER_NAME' already exists${RESET}"
        return
    fi

    echo -e "${ORANGE}Creating K3d cluster: $CLUSTER_NAME...${RESET}"
    k3d cluster create "$CLUSTER_NAME" \
        --port "8888:8888@loadbalancer" \
        --servers 1 \
        --agents 2
    echo -e "${GREEN}Cluster '$CLUSTER_NAME' created${RESET}"

    mkdir -p "$REAL_HOME/.kube"
    k3d kubeconfig merge "$CLUSTER_NAME" --kubeconfig-switch-context -o "$REAL_HOME/.kube/config"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.kube"
    echo -e "${GREEN}kubeconfig saved to $REAL_HOME/.kube/config${RESET}"
}

create_namespaces() {
    echo -e "${ORANGE}Creating namespaces...${RESET}"

    for NS in argocd dev; do
        if kubectl get namespace "$NS" &>/dev/null; then
            echo -e "${GREEN}Namespace '$NS' already exists${RESET}"
        else
            kubectl create namespace "$NS"
            echo -e "${GREEN}Namespace '$NS' created${RESET}"
        fi
    done
}

# --- Main ---
echo -e "${BLUE}=== Setup cluster K3d ===${RESET}"
create_cluster
create_namespaces
echo -e "${BLUE}=== Cluster ready ===${RESET}"
