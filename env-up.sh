#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Starting DevOps Lab setup (k3s + Helm + ArgoCD)..."

# =========================
# Vars
# =========================
ARCH=$(uname -m)
USER_HOME="$HOME"
KUBECONFIG_PATH="$USER_HOME/.kube/config"

if [[ "$ARCH" != "x86_64" ]]; then
  echo "❌ Only x86_64 is supported"
  exit 1
fi

# =========================
# Helper: Safe GPG key install
# =========================
add_gpg_key() {
  local url="$1"
  local output="$2"

  echo "🔑 Adding GPG key from $url"
  curl -fsSL "$url" -o /tmp/key.gpg

  if ! gpg --dry-run --import /tmp/key.gpg &>/dev/null; then
    echo "❌ Invalid GPG key from $url"
    exit 1
  fi

  sudo gpg --dearmor --yes -o "$output" /tmp/key.gpg
  rm -f /tmp/key.gpg
}

# =========================
# Base packages
# =========================
sudo apt-get update -y
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https

sudo update-ca-certificates

# =========================
# Docker
# =========================
echo "🐳 Installing Docker..."

if ! command -v docker &> /dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings

  add_gpg_key \
    https://download.docker.com/linux/ubuntu/gpg \
    /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
fi

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER" || true

echo "✅ Docker ready"

# =========================
# Golang
# =========================
echo "🐹 Installing Golang..."

if ! command -v go &> /dev/null; then
  GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -n 1)

  curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  rm -f /tmp/go.tar.gz
fi

grep -q "/usr/local/go/bin" "$HOME/.bashrc" || \
  echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"

export PATH=$PATH:/usr/local/go/bin

echo "✅ Golang ready"

# =========================
# kubectl (repo oficial)
# =========================
echo "☸️ Installing kubectl..."

if ! command -v kubectl &> /dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings

  add_gpg_key \
    https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
    /etc/apt/keyrings/kubernetes.gpg

  echo \
    "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] \
    https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list

  sudo apt-get update -y
  sudo apt-get install -y kubectl
fi

echo "✅ kubectl ready"

# =========================
# k3s (single-node lab)
# =========================
echo "🚀 Installing k3s..."

if ! command -v k3s &> /dev/null; then
  curl -sfL https://get.k3s.io | \
    INSTALL_K3S_EXEC="--disable traefik" \
    sudo sh -
fi

mkdir -p "$USER_HOME/.kube"
sudo cp /etc/rancher/k3s/k3s.yaml "$KUBECONFIG_PATH"
sudo chown "$USER:$USER" "$KUBECONFIG_PATH"
chmod 600 "$KUBECONFIG_PATH"

grep -q KUBECONFIG "$HOME/.bashrc" || \
  echo "export KUBECONFIG=$KUBECONFIG_PATH" >> "$HOME/.bashrc"

export KUBECONFIG="$KUBECONFIG_PATH"

kubectl wait node --for=condition=Ready --all --timeout=120s

echo "✅ k3s ready"

# =========================
# Helm (official install script)
# =========================
echo "⛵ Installing Helm..."

if ! command -v helm &> /dev/null; then
  curl -fsSL https://get.helm.sh/helm-v3.14.4-linux-amd64.tar.gz -o /tmp/helm.tar.gz

  tar -xzf /tmp/helm.tar.gz -C /tmp
  sudo mv /tmp/linux-amd64/helm /usr/local/bin/helm
  sudo chmod +x /usr/local/bin/helm

  rm -rf /tmp/helm.tar.gz /tmp/linux-amd64
fi

echo "✅ Helm ready"

# =========================
# Argo CD (Helm)
# =========================
echo "🔁 Installing Argo CD..."

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

kubectl get namespace argocd &> /dev/null || kubectl create namespace argocd

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=ClusterIP \
  --set configs.params."server\.insecure"=true

kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

echo "✅ Argo CD ready"

# =========================
# Validation
# =========================
echo "🔍 Validating setup..."

docker --version
go version
kubectl version --client
helm version
kubectl get nodes
kubectl get pods -n argocd

echo ""
echo "🎉 DevOps Lab READY"
echo ""
echo "➡️ Argo CD access:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo ""
echo "➡️ Admin password:"
echo "   kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d"
echo ""

