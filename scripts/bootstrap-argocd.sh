#!/bin/bash
set -e

REGION="us-east-1"
CLUSTER_NAME="enterprise-prod-eks"

echo "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "Checking cluster nodes..."
kubectl get nodes

echo "Creating ArgoCD namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD pods..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "Applying ArgoCD root application..."
kubectl apply -f bootstrap/argocd-nginx.yaml

echo "Checking ArgoCD application..."
kubectl get application -n argocd

echo "Bootstrap completed successfully."

echo "Installing NGINX Ingress Controller..."

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true

helm repo update

helm upgrade --install ingress-nginx \
ingress-nginx/ingress-nginx \
-n ingress-nginx \
--create-namespace \
--set controller.service.type=LoadBalancer

echo "Waiting for Ingress Controller..."

kubectl rollout status deployment ingress-nginx-controller \
-n ingress-nginx \
--timeout=300s

echo "Ingress installation completed."

echo "Installing Monitoring Stack..."

helm repo add prometheus-community \
https://prometheus-community.github.io/helm-charts || true

helm repo update

helm upgrade --install monitoring \
prometheus-community/kube-prometheus-stack \
-n monitoring \
--create-namespace

echo "Monitoring installation completed."
