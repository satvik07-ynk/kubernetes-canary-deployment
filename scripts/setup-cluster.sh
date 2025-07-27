#!/bin/bash

echo "Setting up Kubernetes cluster for canary deployment..."

# Create Kind cluster
echo "Creating Kind cluster..."
kind create cluster --config kind-config.yaml --name canary-demo

# Set kubectl context
kubectl config use-context kind-canary-demo

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install Nginx Ingress Controller
echo "Installing Nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Install Argo Rollouts
echo "Installing Argo Rollouts..."
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Wait for Argo Rollouts to be ready
kubectl wait --namespace argo-rollouts \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argo-rollouts \
  --timeout=120s

# Create monitoring namespace
echo "Setting up monitoring..."
kubectl create namespace monitoring

echo "Cluster setup complete!"
echo "Run 'kubectl get nodes' to verify cluster status"
