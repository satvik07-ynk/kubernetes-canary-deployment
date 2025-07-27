#!/bin/bash

echo "Starting canary deployment to v2..."

# Update the rollout image
kubectl argo rollouts set image demo-app-rollout demo-app=demo-app:v2

echo "Rollout started. Monitor with:"
echo "kubectl argo rollouts get rollout demo-app-rollout --watch"
echo ""
echo "To promote manually:"
echo "kubectl argo rollouts promote demo-app-rollout"
echo ""
echo "To abort:"
echo "kubectl argo rollouts abort demo-app-rollout"
