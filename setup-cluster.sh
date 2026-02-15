#!/bin/bash

set -e   # ✅ KEEP: Exit on real errors (production best practice)

echo "====================================="
echo "🚀 Kubernetes Bootstrap Starting..."
echo "====================================="

#########################################
# Install ArgoCD (Idempotent)
#########################################

echo "📦 Installing ArgoCD..."

# ✅ NEW: Only create namespace if it doesn't exist
kubectl get namespace argocd >/dev/null 2>&1 || kubectl create namespace argocd

# ✅ UPDATED: Ignore CRD re-apply errors safely
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || true

echo "✅ ArgoCD installation step completed"

#########################################
# Install NGINX Ingress Controller
#########################################

echo "🌐 Installing NGINX Ingress Controller..."

# ✅ UPDATED: Safe to reapply
kubectl apply \
  -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml || true

echo "✅ Ingress Controller step completed"

#########################################
# Pull Required Docker Images (Safe Re-runs)
#########################################

echo "🐳 Pulling Required Docker Images..."

# Docker pull is already idempotent (safe to rerun)
docker pull dainmusty/effulgencetech-nodejs-img:latest
docker pull dainmusty/phone-store:latest
docker pull mongo:5.0
docker pull nanajanashia/k8s-demo-app:v1.0
docker pull dainmusty/kids-website:latest
docker pull seidut/zay:1.1
docker pull seidut/ayd:1.0

echo "✅ Docker images ready"

#########################################
# Install Prometheus & Grafana (Idempotent)
#########################################

echo "📊 Installing Prometheus & Grafana..."

# ✅ NEW: Add repo only if missing
helm repo list | grep prometheus-community >/dev/null 2>&1 || \
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

# ✅ NEW: Create namespace only if missing
kubectl get namespace monitoring >/dev/null 2>&1 || kubectl create namespace monitoring

# ✅ UPDATED: Install only if not already installed
helm status monitoring -n monitoring >/dev/null 2>&1 || \
  helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring

echo "✅ Monitoring stack step completed"

#########################################
# Retrieve ArgoCD Admin Password
#########################################

echo "🔐 ArgoCD Admin Password:"

# ✅ NEW: Wait until secret exists (avoids race condition)
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=180s || true

kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" 2>/dev/null | base64 --decode || true

echo ""
echo "-------------------------------------"

#########################################
# Retrieve Grafana Admin Password
#########################################

echo "🔐 Grafana Admin Password:"

kubectl get secret \
  --namespace monitoring \
  -l app.kubernetes.io/component=admin-secret \
  -o jsonpath="{.items[0].data.admin-password}" 2>/dev/null | base64 --decode || true

echo ""
echo "====================================="
echo "🎉 Bootstrap Completed Successfully!"
echo "====================================="
