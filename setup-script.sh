#!/bin/bash
# Setup script for Cloud Service Mesh with Bookinfo application

# Set environment variables
echo "Setting up environment variables..."
export CLUSTER_NAME=gke
export CLUSTER_ZONE=$1  # First argument should be your cluster zone
export GCLOUD_PROJECT=$(gcloud config get-value project)

# Configure kubectl
echo "Configuring kubectl..."
gcloud container clusters get-credentials $CLUSTER_NAME \
  --zone $CLUSTER_ZONE --project $GCLOUD_PROJECT

# Verify cluster status
echo "Verifying cluster status..."
gcloud container clusters list

# Check Cloud Service Mesh control plane
echo "Checking Cloud Service Mesh control plane..."
kubectl get pods -n asm-ingress
kubectl get service -n asm-ingress

# Verify Bookinfo deployment
echo "Verifying Bookinfo application deployment..."
kubectl get pods
kubectl get services

# Create ingress namespace and deploy gateway
echo "Creating ingress namespace and deploying gateway..."
kubectl create namespace ingress
kubectl label namespace ingress istio.io/rev=asm-managed --overwrite
kubectl apply -n ingress -f ingress.yaml

# Deploy Gateway and VirtualService resources
echo "Deploying Gateway and VirtualService resources..."
kubectl apply -f bookinfo-gateway.yaml
kubectl apply -f bookinfo-virtualservice.yaml

# Get and store the external gateway URL
echo "Getting external gateway URL..."
export GATEWAY_URL=$(kubectl get svc -n ingress istio-ingressgateway \
-o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Gateway URL: $GATEWAY_URL"

# Apply destination rules for service versions
echo "Applying destination rules..."
kubectl apply -f destination-rule-all.yaml

echo "Setup complete! You can access the Bookinfo application at http://$GATEWAY_URL/productpage"