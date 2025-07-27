#!/bin/bash

echo "Cleaning up canary deployment project..."

# Delete Kubernetes resources
kubectl delete -f k8s/ --ignore-not-found=true
kubectl delete -f monitoring/ --ignore-not-found=true

# Delete namespaces
kubectl delete namespace monitoring --ignore-not-found=true
kubectl delete namespace argo-rollouts --ignore-not-found=true

# Delete Kind cluster
kind delete cluster --name canary-demo

# Remove hosts entry
if grep -q "demo-app.local" /etc/hosts; then
    sudo sed -i '/demo-app.local/d' /etc/hosts
    echo "Removed demo-app.local from /etc/hosts"
fi

echo "Cleanup complete!"
