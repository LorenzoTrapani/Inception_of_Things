#!/bin/bash

set -e  # Esci immediatamente se un comando fallisce

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RESET='\033[0m'

install_docker() {
    echo -e "${BLUE}Starting Docker installation...${RESET}"

    # elimina vecchie versioni docker se presenti
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release

    # aggiunge la chiave gpg ufficiale Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Aggiunge il repository Docker e verifica pacchetti con la chiave gpg
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io

    systemctl enable docker
    systemctl start docker
    usermod -aG docker "$USER"

    echo -e "${GREEN}Docker installed: $(docker --version)${RESET}"
}

install_kubectl() {
    echo -e "${BLUE}Starting kubectl installation...${RESET}"

    # check per ultima versione stabile
    KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)

    curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
        -o /usr/local/bin/kubectl

    chmod +x /usr/local/bin/kubectl

    echo -e "${GREEN}kubectl installed: $(kubectl version --client)${RESET}"
}


install_k3d() {
    if command -v k3d &>/dev/null; then
        echo -e "${GREEN}K3d already installed: $(k3d version | head -1)${RESET}"
        return
    fi

    echo -e "${BLUE}Starting K3d installation...${RESET}"

    curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

    echo -e "${GREEN}K3d installed: $(k3d version | head -1)${RESET}"
}


# installare ArgoCD CLI opzionale ma utile per gestire argocd da terminale
install_argocd_cli() {
    echo -e "${BLUE}Starting ArgoCD CLI installation...${RESET}"

    # check per ultima versione stabile
    ARGOCD_VERSION=$(curl -fsSL https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)

    curl -fsSL "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64" \
        -o /usr/local/bin/argocd

    chmod +x /usr/local/bin/argocd

    echo -e "${GREEN}ArgoCD CLI installed: $(argocd version --client --short)${RESET}"
}


# --- Main ---
echo "=== Installing dependencies... ==="
install_docker
install_kubectl
install_k3d
install_argocd_cli
echo "=== Installation completed ==="
