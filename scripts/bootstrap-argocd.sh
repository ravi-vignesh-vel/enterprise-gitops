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
