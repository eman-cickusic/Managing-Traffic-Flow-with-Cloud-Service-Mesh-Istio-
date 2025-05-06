# Managing Traffic Flow with Cloud Service Mesh (Istio)

This repository demonstrates how to implement and manage a cloud service mesh using Istio on a Google Kubernetes Engine (GKE) cluster. The project showcases various traffic management capabilities and best practices using the Bookinfo sample application.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Implementation Tasks](#implementation-tasks)
  - [Task 1: Lab Setup](#task-1-lab-setup)
  - [Task 2: Install Gateways for Ingress](#task-2-install-gateways-for-ingress)
  - [Task 3: View Routing with Service Mesh Dashboard](#task-3-view-routing-with-service-mesh-dashboard)
  - [Task 4: Apply Default Destination Rules](#task-4-apply-default-destination-rules)
  - [Task 5: Apply Virtual Services for Default Routing](#task-5-apply-virtual-services-for-default-routing)
  - [Task 6: User-Specific Routing](#task-6-user-specific-routing)
  - [Task 7: Traffic Shifting Between Versions](#task-7-traffic-shifting-between-versions)
  - [Task 8: Implementing Timeouts](#task-8-implementing-timeouts)
  - [Task 9: Adding Circuit Breakers](#task-9-adding-circuit-breakers)
- [Architecture](#architecture)
- [Learning Outcomes](#learning-outcomes)
- [Resources](#resources)

## Overview

A Cloud Service Mesh is an architecture that enables managed, observable, and secure communication among microservices, making it easier to create robust enterprise applications. This project demonstrates how to use Istio's traffic management model which relies on:

- **Control plane**: Manages and configures the Envoy proxies to route traffic and enforce policies
- **Data plane**: Encompasses all network communication between microservices performed at runtime by the Envoy proxies

The mesh enables features including service discovery, load balancing, and traffic routing/control.

## Prerequisites

- Google Cloud Platform account
- GKE cluster with Cloud Service Mesh installed
- kubectl configured to access your cluster
- Istio command-line tools
- Basic knowledge of Kubernetes and microservices

## Installation

1. **Set up environment variables:**
   ```bash
   export CLUSTER_NAME=gke
   export CLUSTER_ZONE=your-cluster-zone
   export GCLOUD_PROJECT=$(gcloud config get-value project)
   ```

2. **Configure kubectl access:**
   ```bash
   gcloud container clusters get-credentials $CLUSTER_NAME \
     --zone $CLUSTER_ZONE --project $GCLOUD_PROJECT
   ```

3. **Verify cluster and Cloud Service Mesh installation:**
   ```bash
   gcloud container clusters list
   kubectl get pods -n asm-ingress
   kubectl get service -n asm-ingress
   ```

4. **Verify Bookinfo deployment:**
   ```bash
   kubectl get pods
   kubectl get services
   ```

## Implementation Tasks

### Task 1: Lab Setup

The initial setup includes a GKE cluster named "gke" with Cloud Service Mesh installed and the Bookinfo multi-service sample application deployed. The application consists of several microservices:
- productpage
- details
- reviews (with v1, v2, and v3 versions)
- ratings

### Task 2: Install Gateways for Ingress

Gateways in Cloud Service Mesh allow mesh features such as monitoring, mTLS, and advanced routing to be applied to traffic entering the cluster.

1. Create a namespace for the gateway:
   ```bash
   kubectl create namespace ingress
   kubectl label namespace ingress istio.io/rev=asm-managed --overwrite
   ```

2. Deploy the gateway configuration:
   ```bash
   kubectl apply -n ingress -f ingress.yaml
   ```

3. Deploy the Gateway resource to specify port and protocol:
   ```bash
   kubectl apply -f gateway.yaml
   ```

4. Deploy the VirtualService to route traffic from the gateway to the BookInfo application:
   ```bash
   kubectl apply -f bookinfo-virtualservice.yaml
   ```

5. Get the external IP:
   ```bash
   export GATEWAY_URL=$(kubectl get svc -n ingress istio-ingressgateway \
   -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
   ```

### Task 3: View Routing with Service Mesh Dashboard

This task demonstrates how to use the Service Mesh dashboard to:
- View service topology
- Analyze traffic distribution
- Monitor outbound connections
- Observe traffic patterns between services and their versions

### Task 4: Apply Default Destination Rules

Destination rules define all available service versions (subsets):

```bash
kubectl apply -f destination-rule-all.yaml
```

This defines DestinationRule resources for each service, specifying the available versions.

### Task 5: Apply Virtual Services for Default Routing

Configure all traffic to be routed to v1 of each service:

```bash
kubectl apply -f virtual-service-all-v1.yaml
```

This routes all traffic to v1 of the services, regardless of which version was previously receiving traffic.

### Task 6: User-Specific Routing

Route traffic based on user identity:

```bash
kubectl apply -f virtual-service-reviews-test-v2.yaml
```

This routes traffic from user "jason" to reviews:v2 (with star ratings), while all other traffic goes to reviews:v1 (no ratings).

### Task 7: Traffic Shifting Between Versions

Gradually migrate traffic from one service version to another:

1. Route all traffic to v1:
   ```bash
   kubectl apply -f virtual-service-all-v1.yaml
   ```

2. Shift 50% of traffic to v3:
   ```bash
   kubectl apply -f virtual-service-reviews-50-v3.yaml
   ```

3. Shift 100% of traffic to v3:
   ```bash
   kubectl apply -f virtual-service-reviews-v3.yaml
   ```

### Task 8: Implementing Timeouts

Add request timeouts to avoid waiting indefinitely for service replies:

1. Route traffic to v2 of reviews:
   ```bash
   kubectl apply -f reviews-v2-virtualservice.yaml
   ```

2. Add a delay to ratings service:
   ```bash
   kubectl apply -f ratings-delay-virtualservice.yaml
   ```

3. Add a timeout for calls to the reviews service:
   ```bash
   kubectl apply -f reviews-timeout-virtualservice.yaml
   ```

### Task 9: Adding Circuit Breakers

Configure circuit breaking for connections, requests, and outlier detection:

1. Create a destination rule with circuit breaking settings:
   ```bash
   kubectl apply -f productpage-circuit-breaker.yaml
   ```

2. Test circuit breaking using a load testing client:
   ```bash
   kubectl apply -f fortio-deploy.yaml
   ```

3. Send traffic to trip the circuit breaker:
   ```bash
   kubectl exec "$FORTIO_POD" -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://${GATEWAY_URL}/productpage
   ```

## Architecture

The Bookinfo application consists of four separate microservices:

1. **productpage** - Calls the details and reviews microservices
2. **details** - Contains book information
3. **reviews** - Contains book reviews and calls the ratings service
   - v1: Doesn't call the ratings service
   - v2: Calls the ratings service and displays black stars
   - v3: Calls the ratings service and displays red stars
4. **ratings** - Contains book rating information

The application uses the Istio service mesh to manage traffic flow between these components.

## Learning Outcomes

Through this project, you'll learn how to:

- Configure and use Istio Gateways
- Apply destination rules for different service versions
- Create virtual services to control traffic routing
- Implement user-specific routing based on identity
- Gradually shift traffic between service versions
- Implement timeouts for service resiliency
- Configure circuit breakers to handle failures gracefully
- Monitor and visualize traffic in the Service Mesh dashboard

## Resources

- [Istio Documentation](https://istio.io/docs/)
- [Google Cloud Service Mesh Documentation](https://cloud.google.com/service-mesh/docs)
- [Bookinfo Sample Application](https://istio.io/docs/examples/bookinfo/)
