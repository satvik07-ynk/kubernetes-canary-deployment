#!/bin/bash

echo "Deploying initial application..."

# Apply monitoring
kubectl apply -f monitoring/prometheus-config.yaml

# Apply application manifests
kubectl apply -f k8s/app-manifests.yaml
kubectl apply -f k8s/rollout-rbac.yaml
kubectl apply -f k8s/rollout.yaml

echo "Waiting for initial deployment..."
kubectl wait --for=condition=Available rollout/demo-app-rollout --timeout=300s

echo "Initial deployment complete!"
echo "Run 'kubectl argo rollouts get rollout demo-app-rollout' to check status"
