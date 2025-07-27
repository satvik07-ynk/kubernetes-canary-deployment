#!/bin/bash

echo "Testing traffic distribution..."

# Add entry to /etc/hosts for local testing
if ! grep -q "demo-app.local" /etc/hosts; then
    echo "127.0.0.1 demo-app.local" | sudo tee -a /etc/hosts
    echo "Added demo-app.local to /etc/hosts"
fi

# Port forward ingress controller
echo "Starting port-forward to ingress controller..."
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80 &
PORT_FORWARD_PID=$!

sleep 5

echo "Sending 100 requests to check traffic distribution..."
for i in {1..100}; do
  curl -s -H "Host: demo-app.local" http://localhost:8080/ | jq -r '.version' 2>/dev/null || echo "Error"
done | sort | uniq -c

echo "Stopping port-forward..."
kill $PORT_FORWARD_PID 2>/dev/null
