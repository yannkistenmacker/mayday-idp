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
  apt-transport-https \
  jq

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

# FIX: só adiciona ao grupo se não for root
if [[ "$USER" != "root" ]]; then
  sudo usermod -aG docker "$USER" || true
  echo "⚠️  Logout/login necessário para aplicar o grupo docker ao usuário $USER"
fi

echo "✅ Docker $(docker --version) ready"

# =========================
# Golang
# =========================
echo "🐹 Installing Golang..."

if ! command -v go &> /dev/null; then
  # FIX: validação de versão antes de usar
  GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -n 1)
  [[ -z "$GO_VERSION" ]] && { echo "❌ Falha ao obter versão do Go"; exit 1; }
  echo "   → Go version: $GO_VERSION"

  curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  rm -f /tmp/go.tar.gz
fi

grep -q "/usr/local/go/bin" "$HOME/.bashrc" || \
  echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"

export PATH=$PATH:/usr/local/go/bin

echo "✅ Go $(go version) ready"

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

# KUBECONFIG disponível para sessões não-interativas (ex: systemd, cron)
grep -q KUBECONFIG "$HOME/.bashrc" || \
  echo "export KUBECONFIG=$KUBECONFIG_PATH" >> "$HOME/.bashrc"

grep -q "KUBECONFIG" /etc/environment || \
  echo "KUBECONFIG=$KUBECONFIG_PATH" | sudo tee -a /etc/environment > /dev/null

export KUBECONFIG="$KUBECONFIG_PATH"

# FIX: sleep para evitar race condition antes do wait
echo "   → Aguardando node registrar no cluster..."
sleep 5
kubectl wait node --for=condition=Ready --all --timeout=120s

echo "✅ k3s ready"

# =========================
# kubectl — alinhado com a versão do k3s
# =========================
echo "☸️  Installing kubectl..."

if ! command -v kubectl >/dev/null 2>&1; then
  # FIX: detecta versão minor do k3s para evitar divergência de API
  K3S_MINOR=$(k3s --version | grep -oP 'v\d+\.\K\d+' | head -n1)
  K8S_REPO_VERSION="v1.${K3S_MINOR}"
  echo "   → Usando kubectl alinhado ao k3s: ${K8S_REPO_VERSION}"

  sudo install -m 0755 -d /etc/apt/keyrings

  curl -fsSL \
    "https://pkgs.k8s.io/core:/stable:/${K8S_REPO_VERSION}/deb/Release.key" \
    | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

  sudo chmod 644 /etc/apt/keyrings/kubernetes.gpg

  cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_REPO_VERSION}/deb/ /
EOF

  sudo apt-get update
  sudo apt-get install -y kubectl
fi

echo "✅ $(kubectl version --client --short 2>/dev/null || kubectl version --client) ready"

# =========================
# Helm — versão latest dinâmica
# =========================
echo "⛵ Installing Helm..."

if ! command -v helm &> /dev/null; then
  # FIX: busca versão latest em vez de hardcode
  HELM_VERSION=$(curl -fsSL https://api.github.com/repos/helm/helm/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  [[ -z "$HELM_VERSION" ]] && { echo "❌ Falha ao obter versão do Helm"; exit 1; }
  echo "   → Helm version: $HELM_VERSION"

  curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o /tmp/helm.tar.gz
  tar -xzf /tmp/helm.tar.gz -C /tmp
  sudo mv /tmp/linux-amd64/helm /usr/local/bin/helm
  sudo chmod +x /usr/local/bin/helm
  rm -rf /tmp/helm.tar.gz /tmp/linux-amd64
fi

echo "✅ Helm $(helm version --short) ready"

# =========================
# Argo CD (Helm)
# =========================
echo "🔁 Installing Argo CD..."

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

kubectl get namespace argocd &> /dev/null || kubectl create namespace argocd

# FIX: values inline via heredoc — evita problemas de escape com --set no ponto
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  -f - <<'EOF'
server:
  service:
    type: ClusterIP
configs:
  params:
    server.insecure: true
EOF

kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

echo "✅ Argo CD ready"

# =========================
# Sealed Secrets (Bitnami)
# =========================
echo "🔐 Installing Sealed Secrets controller..."

helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update

helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  --take-ownership \
  --namespace kube-system \
  --set fullnameOverride=sealed-secrets

kubectl rollout status deployment/sealed-secrets -n kube-system --timeout=180s

echo "✅ Sealed Secrets ready"
echo "   Controller: sealed-secrets (namespace kube-system)"
echo "   Seal the Backstage secret with: scripts/seal-backstage-secret.sh"

# =========================
# Validação final
# =========================
echo ""
echo "🔍 Validando setup..."
echo "---"
docker --version
go version
kubectl version --client
helm version --short
echo "---"
kubectl get nodes
echo "---"
kubectl get pods -n argocd
echo ""
echo "🎉 DevOps Lab READY"
echo ""
echo "➡️  Argo CD access:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo ""
echo "➡️  Admin password:"
echo "   kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "⚠️  Se adicionou docker ao grupo, faça logout/login para aplicar."
echo ""
