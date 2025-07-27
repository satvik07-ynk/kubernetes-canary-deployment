#!/bin/bash

echo "Building Docker images..."

# Build v1
cd app
echo "Building demo-app:v1..."
docker build -t demo-app:v1 .

# Create v2 version with modified response
echo "Building demo-app:v2..."
cp main.py main.py.backup
sed -i 's/Hello from FastAPI/Welcome to FastAPI v2 from/g' main.py
docker build -t demo-app:v2 .
mv main.py.backup main.py

cd ..

# Load images into kind cluster
echo "Loading images into Kind cluster..."
kind load docker-image demo-app:v1 --name canary-demo
kind load docker-image demo-app:v2 --name canary-demo

echo "Images built and loaded successfully!"
docker images | grep demo-app
