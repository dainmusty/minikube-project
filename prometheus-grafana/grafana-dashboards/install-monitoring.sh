#!/usr/bin/env bash
set -e

NAMESPACE="monitoring"
RELEASE_NAME="monitoring"

echo "🔍 Checking kubectl..."
command -v kubectl >/dev/null 2>&1 || {
  echo "❌ kubectl not found. Please install kubectl first."
  exit 1
}

echo "🔍 Checking cluster connectivity..."
kubectl get nodes >/dev/null 2>&1 || {
  echo "❌ Kubernetes cluster not reachable. Is Docker Desktop Kubernetes running?"
  exit 1
}

echo "🔍 Checking Helm..."
if ! command -v helm >/dev/null 2>&1; then
  echo "⚙️ Helm not found. Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "✅ Helm already installed"
fi
helm repo update

echo "📁 Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "🚀 Installing kube-prometheus-stack..."
helm upgrade --install $RELEASE_NAME prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n $NAMESPACE --timeout=600s

echo ""
echo "✅ Installation complete!"
echo ""

echo "🔑 Grafana Admin Password:"
kubectl get secret -n $NAMESPACE ${RELEASE_NAME}-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
echo ""
echo ""

echo ""
echo "🎉 Monitoring stack is ready!"
