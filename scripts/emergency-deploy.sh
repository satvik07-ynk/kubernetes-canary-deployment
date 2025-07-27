#!/bin/bash

echo "EMERGENCY DEPLOYMENT - Bypassing canary process"
echo "This will deploy directly to 100% traffic"
echo ""
read -p "Are you sure you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Emergency deployment cancelled"
    exit 1
fi

echo "Applying emergency deployment..."
kubectl apply -f k8s/emergency-deployment.yaml

echo "Waiting for emergency deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/demo-app-emergency

echo "Emergency deployment completed!"
echo "Access via: demo-app-emergency.local"
