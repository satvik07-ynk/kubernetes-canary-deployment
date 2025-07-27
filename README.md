# Kubernetes Canary Deployment with Argo Rollouts

A complete implementation of weight-based canary deployments in Kubernetes using Argo Rollouts, featuring manual approvals, automatic rollbacks, and comprehensive monitoring.

## 🎯 What This Project Does

This project demonstrates a **production-ready canary deployment pipeline** that:

- ✅ **Gradually rolls out new versions** using traffic weights: 5% → 25% → 50% → 100%
- ✅ **Requires manual approval** at each stage before proceeding
- ✅ **Automatically rolls back** if error rates exceed 10%
- ✅ **Provides emergency deployment** bypass for critical hotfixes
- ✅ **Monitors everything** with Prometheus metrics and detailed logging
- ✅ **Demonstrates both success and failure scenarios**

## 🏗 Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client        │───▶│  Nginx Ingress  │───▶│   Services      │
│   Requests      │    │  (Traffic Split)│    │  (Stable/Canary)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                         │
                              ▼                         ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  Argo Rollouts  │    │    FastAPI      │
                       │  (Controller)   │    │  Pods (v1/v2)   │
                       └─────────────────┘    └─────────────────┘
                              │                         │
                              ▼                         ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Prometheus    │◀───│    Metrics      │
                       │  (Monitoring)   │    │   /metrics      │
                       └─────────────────┘    └─────────────────┘
```

### Key Components

1. **Kind Cluster**: Local Kubernetes environment
2. **Nginx Ingress Controller**: Routes traffic and manages weight-based splitting
3. **Argo Rollouts**: Advanced deployment controller for canary strategies
4. **FastAPI Application**: Demo app with v1 and v2 versions
5. **Prometheus**: Metrics collection and monitoring
6. **Analysis Templates**: Automated health checks and rollback triggers

## 📁 Project Structure

```
kubernetes-canary-deployment/
├── app/                        # FastAPI Demo Application
│   ├── main.py                 # Application code with metrics
│   ├── requirements.txt        # Python dependencies
│   └── Dockerfile             # Container image definition
├── k8s/                       # Kubernetes Manifests
│   ├── app-manifests.yaml     # Services, ConfigMaps, Ingress
│   ├── rollout.yaml           # Argo Rollout configuration
│   ├── rollout-rbac.yaml      # RBAC permissions
│   └── emergency-deployment.yaml # Emergency bypass deployment
├── monitoring/                # Monitoring Configuration
│   └── prometheus-config.yaml # Prometheus setup
├── scripts/                   # Automation Scripts
│   ├── setup-cluster.sh       # Complete cluster setup
│   ├── build-images.sh        # Build and load Docker images
│   ├── deploy-initial.sh      # Deploy initial version
│   ├── deploy-v2.sh           # Start canary deployment
│   ├── test-traffic.sh        # Test traffic distribution
│   ├── emergency-deploy.sh    # Emergency deployment
│   └── cleanup.sh             # Clean up everything
├── kind-config.yaml           # Kind cluster configuration
├── .gitignore                 # Git ignore rules
└── README.md                  # This comprehensive guide
```

## 🚀 Quick Start Guide

### Prerequisites

```bash
# Install required tools (Ubuntu/Debian)
sudo apt-get update

# Install Docker
sudo apt-get install docker.io -y
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install Argo Rollouts CLI
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x ./kubectl-argo-rollouts-linux-amd64
sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Install jq (for JSON parsing in scripts)
sudo apt-get install jq -y
```

### Step-by-Step Deployment

#### 1. Clone and Setup
```bash
git clone https://github.com/satvik07-ynk/kubernetes-canary-deployment.git
cd kubernetes-canary-deployment
```

#### 2. Create Kubernetes Cluster
```bash
# This creates a 3-node Kind cluster with ingress support
./scripts/setup-cluster.sh

# Verify cluster is ready
kubectl get nodes
kubectl get pods -A
```

#### 3. Build Application Images
```bash
# Builds demo-app:v1 and demo-app:v2, loads them into Kind
./scripts/build-images.sh

# Verify images are loaded
docker images | grep demo-app
```

#### 4. Deploy Initial Version (v1)
```bash
# Deploys v1 of the application with all monitoring
./scripts/deploy-initial.sh

# Wait for deployment to be ready
kubectl argo rollouts get rollout demo-app-rollout --watch
```

#### 5. Test Initial Deployment
```bash
# Test the application
kubectl port-forward service/demo-app-service 8080:8000 &
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/version
```

#### 6. Start Canary Deployment (v1 → v2)
```bash
# This starts the canary process
./scripts/deploy-v2.sh

# Monitor the rollout in real-time
kubectl argo rollouts get rollout demo-app-rollout --watch
```

#### 7. Manual Approval Process

The rollout will pause at each stage waiting for manual approval:

```bash
# At 5% canary traffic - approve to continue
kubectl argo rollouts promote demo-app-rollout

# At 25% canary traffic - approve to continue  
kubectl argo rollouts promote demo-app-rollout

# At 50% canary traffic - approve to continue
kubectl argo rollouts promote demo-app-rollout

# Final promotion to 100%
kubectl argo rollouts promote demo-app-rollout
```

#### 8. Test Traffic Distribution
```bash
# This sends 100 requests and shows version distribution
./scripts/test-traffic.sh

# Example output:
#     85 v1
#     15 v2    # Shows 15% traffic going to canary (v2)
```

## 🔍 Monitoring and Observability

### View Rollout Status
```bash
# Real-time rollout monitoring
kubectl argo rollouts get rollout demo-app-rollout --watch

# Rollout history
kubectl argo rollouts history demo-app-rollout

# Detailed rollout information
kubectl describe rollout demo-app-rollout
```

### Prometheus Metrics
```bash
# Access Prometheus UI
kubectl port-forward -n monitoring service/prometheus-service 9090:9090 &

# Open http://localhost:9090 in browser
# Key metrics to monitor:
# - http_requests_total
# - rate(http_requests_total[5m])
# - Error rate: rate(http_requests_total{status=~"5.."}[5m])
```

### Application Logs
```bash
# View application logs
kubectl logs -l app=demo-app -f

# View specific pod logs
kubectl logs deployment/demo-app-rollout-stable -f
kubectl logs deployment/demo-app-rollout-canary -f
```

## 🚨 Failure Scenarios and Rollback

### Automatic Rollback (Error Rate > 10%)

To demonstrate automatic rollback:

```bash
# 1. Start a canary deployment
./scripts/deploy-v2.sh

# 2. Simulate high error rate (modify configmap)
kubectl patch configmap demo-app-config --patch '{"data":{"FAILURE_RATE":"0.15"}}'

# 3. Restart pods to pick up new config
kubectl rollout restart rollout/demo-app-rollout

# 4. Watch automatic rollback happen
kubectl argo rollouts get rollout demo-app-rollout --watch

# The system will automatically abort and rollback when error rate > 10%
```

### Manual Rollback

```bash
# Abort current rollout at any stage
kubectl argo rollouts abort demo-app-rollout

# Rollback to previous stable version
kubectl argo rollouts undo demo-app-rollout

# Check rollback status
kubectl argo rollouts status demo-app-rollout
```

## 🚑 Emergency Deployment

For critical hotfixes that need to bypass the canary process:

```bash
# Deploy directly to 100% traffic (bypasses canary)
./scripts/emergency-deploy.sh

# This creates a separate deployment that gets immediate full traffic
# Use only for critical security fixes or urgent patches
```

## 📊 Traffic Weight Progression

The canary deployment follows this progression:

| Stage | Stable (v1) | Canary (v2) | Action Required |
|-------|-------------|-------------|-----------------|
| Initial | 100% | 0% | - |
| Stage 1 | 95% | 5% | Manual Approval |
| Stage 2 | 75% | 25% | Manual Approval |
| Stage 3 | 50% | 50% | Manual Approval |
| Final | 0% | 100% | Automatic |

## 🔧 Configuration Options

### Rollout Configuration
Edit `k8s/rollout.yaml` to customize:

```yaml
strategy:
  canary:
    steps:
    - setWeight: 5    # Change initial canary percentage
    - pause: {}       # Manual approval step
    - setWeight: 25   # Customize progression weights
    # ... more steps
```

### Analysis Configuration
Modify error rate thresholds in `k8s/rollout.yaml`:

```yaml
metrics:
- name: error-rate
  successCondition: result < 0.10  # Change from 10% threshold
  failureLimit: 3                  # Number of failed checks before rollback
```

### Application Configuration
Update `k8s/app-manifests.yaml`:

```yaml
data:
  APP_VERSION: "v1"
  FAILURE_RATE: "0.0"  # Simulate failure rate (0.0 = 0%, 0.1 = 10%)
```

## 🧪 Testing Scenarios

### Test 1: Successful Canary Deployment
```bash
./scripts/deploy-v2.sh
# Follow prompts, approve each stage
# Verify v2 is fully deployed
```

### Test 2: Failed Deployment with Rollback
```bash
# Start deployment
./scripts/deploy-v2.sh

# Introduce failures
kubectl patch configmap demo-app-config --patch '{"data":{"FAILURE_RATE":"0.20"}}'

# Watch automatic rollback
kubectl argo rollouts get rollout demo-app-rollout --watch
```

### Test 3: Manual Abort and Rollback
```bash
# Start deployment
./scripts/deploy-v2.sh

# Wait for 25% stage, then abort
kubectl argo rollouts abort demo-app-rollout

# Verify rollback to stable version
kubectl argo rollouts status demo-app-rollout
```

## 🛠 Troubleshooting

### Common Issues

#### 1. Cluster Creation Fails
```bash
# Check Docker is running
sudo systemctl status docker

# Clean up and retry
kind delete cluster --name canary-demo
./scripts/setup-cluster.sh
```

#### 2. Images Not Found
```bash
# Rebuild and reload images
./scripts/build-images.sh

# Verify images in Kind
docker exec -it canary-demo-control-plane crictl images | grep demo-app
```

#### 3. Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify ingress rules
kubectl describe ingress demo-app-ingress
```

#### 4. Rollout Stuck
```bash
# Check rollout events
kubectl describe rollout demo-app-rollout

# Check analysis runs
kubectl get analysisruns

# Force promotion if needed
kubectl argo rollouts promote demo-app-rollout
```

#### 5. Metrics Not Available
```bash
# Check Prometheus is running
kubectl get pods -n monitoring

# Port forward and check targets
kubectl port-forward -n monitoring service/prometheus-service 9090:9090
# Visit http://localhost:9090/targets
```

### Debug Commands

```bash
# Check overall cluster health
kubectl get nodes
kubectl get pods -A

# Check specific components
kubectl get rollouts
kubectl get services
kubectl get ingress

# View events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check logs
kubectl logs -n argo-rollouts deployment/argo-rollouts
kubectl logs -l app=demo-app
```

## 🧹 Cleanup

To remove everything:

```bash
# Complete cleanup - removes cluster, images, and host entries
./scripts/cleanup.sh

# Manual cleanup if needed
kind delete cluster --name canary-demo
sudo sed -i '/demo-app.local/d' /etc/hosts
```

## 📝 Key Learning Outcomes

After completing this project, you'll understand:

1. **Canary Deployment Patterns**: How to safely roll out new versions
2. **Kubernetes Controllers**: Advanced deployment strategies beyond basic Deployments
3. **Traffic Management**: Ingress-based traffic splitting and routing
4. **Monitoring Integration**: Prometheus metrics and automated decision making
5. **GitOps Practices**: Declarative configuration and rollback strategies
6. **Production Safety**: Manual approvals, automatic rollbacks, emergency procedures

## 🤝 Contributing

This project is designed for learning and demonstration. Feel free to:

- Modify rollout strategies
- Add additional metrics
- Implement different failure scenarios
- Enhance the monitoring dashboard
- Add more sophisticated health checks

## 📚 Additional Resources

- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Prometheus Monitoring](https://prometheus.io/docs/)
- [Kind User Guide](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

## 📋 Project Checklist

- [x] Weight-based canary rollouts (5% → 25% → 50% → 100%)
- [x] Manual approvals at each stage
- [x] Automatic rollback on high error rates (>10%)
- [x] Emergency deployment bypass
- [x] Complete audit logging and monitoring
- [x] Prometheus integration with custom metrics
- [x] Production-ready FastAPI application
- [x] Comprehensive documentation and troubleshooting
- [x] Success and failure scenario demonstrations

## 🎉 Success Criteria

You've successfully completed this project when you can:

1. ✅ Deploy the initial version (v1) successfully
2. ✅ Start a canary deployment and observe traffic splitting
3. ✅ Manually approve promotions at each stage
4. ✅ Demonstrate automatic rollback on high error rates
5. ✅ Use emergency deployment for urgent updates
6. ✅ Monitor the entire process through Prometheus metrics
7. ✅ Understand and explain each component's role

---

**Happy Deploying!** 🚀

For questions or issues, check the troubleshooting section or review the debug commands.
