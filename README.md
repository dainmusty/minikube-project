# Prometheus Grafana Observability Stack

This project demonstrates how to build a **Kubernetes observability platform** using Prometheus, Grafana, and Alertmanager.

The stack provides full visibility into Kubernetes workloads including:

• ArgoCD GitOps controllers  
• MongoDB database metrics  
• Kubernetes infrastructure health  
• Application performance metrics  

The goal of this project is to simulate how platform and SRE teams implement **production-grade monitoring and alerting** for cloud-native systems.

---

# Architecture Overview

The observability stack is deployed using the **kube-prometheus-stack Helm chart**, which bundles several core monitoring components.

Key components include:

Prometheus – metrics collection and time-series database  
Grafana – visualization dashboards  
Alertmanager – alert routing and notifications  
Node Exporter – host-level metrics  
Kube State Metrics – Kubernetes object metrics  

These components work together to provide **real-time operational visibility** into the cluster.

---

# Environment

The observability platform was developed and tested on a **local Kubernetes cluster** using Docker Desktop / Minikube.

This approach allows dashboards, alerts, and monitoring configurations to be designed and tested locally before deploying to a cloud environment such as **Amazon EKS**.

---

# Observability Features

The platform includes monitoring and dashboards for several key services.

## Kubernetes Infrastructure Monitoring

Prometheus collects cluster-level metrics including:

• node CPU and memory usage  
• pod resource utilization  
• cluster health and capacity  

Grafana dashboards provide real-time visualization of these metrics.

---

## ArgoCD Monitoring

ArgoCD metrics are scraped by Prometheus using **ServiceMonitor resources**.

This enables dashboards that track:

• application sync status  
• reconciliation loops  
• deployment health  
• controller performance

These insights help platform teams detect GitOps synchronization issues early.

---

## MongoDB Monitoring

MongoDB metrics are collected to track database health and performance.

Metrics monitored include:

• database connections  
• query performance  
• memory usage  
• replication metrics

These dashboards allow operators to quickly detect database performance issues.

---

# Alerting

Alerting is implemented using **Prometheus Alertmanager**.

Alerts can be configured for scenarios such as:

• high CPU or memory usage  
• pod crashes or restart loops  
• application downtime  
• resource exhaustion  

This ensures that operational issues can be detected and addressed quickly.

---

# Deployment Steps

## 1. Create Monitoring Namespace

```
kubectl create namespace monitoring
```

---

## 2. Add Prometheus Helm Repository

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

---

## 3. Install kube-prometheus-stack

```
helm install monitoring prometheus-community/kube-prometheus-stack \
--namespace monitoring
```

This installs:

• Prometheus  
• Grafana  
• Alertmanager  
• Node Exporter  
• Kube State Metrics

---

# Accessing Grafana

Forward the Grafana service:

```
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```

Open:

```
http://localhost:3000
```

Retrieve the Grafana admin password:

```
kubectl get secret -n monitoring monitoring-grafana \
-o jsonpath="{.data.admin-password}" | base64 --decode
```

---

# Accessing Prometheus

```
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Prometheus UI:

```
http://localhost:9090
```

---

# Alertmanager

```
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093
```

Alertmanager UI:

```
http://localhost:9093
```

---

# ServiceMonitors

Prometheus discovers application metrics through **ServiceMonitor resources**.

ServiceMonitors define:

• which services to monitor  
• which endpoints expose metrics  
• scrape intervals  

This allows platform teams to extend monitoring coverage easily for new services.

---

# Grafana Dashboards

Custom Grafana dashboards were created to monitor:

• Kubernetes cluster health  
• ArgoCD controllers and applications  
• MongoDB performance metrics  
• microservices workload health  

These dashboards provide a centralized view of the system's operational status.

---

# Security and Networking

The project also demonstrates several Kubernetes operational best practices:

• ingress-based routing using NGINX  
• namespace isolation for workloads  
• Kubernetes NetworkPolicies implementing zero-trust networking  

These controls prevent unauthorized communication between services.

---

# Persistence

Prometheus and Grafana data persistence can be enabled using **Persistent Volume Claims (PVCs)** to ensure monitoring data survives pod restarts.

This is critical for maintaining historical metrics and debugging long-term performance trends.

---

# Key Lessons Learned

Building an observability platform highlighted several important principles used by SRE and platform teams.

### Observability must be designed early

Monitoring should be built into the platform rather than added after systems are deployed.

### Metrics alone are not enough

Dashboards and alerts are necessary to transform raw metrics into actionable operational insights.

### Service discovery simplifies monitoring

Using ServiceMonitors allows Prometheus to automatically detect new services as they are deployed.

### Dashboards should focus on operational questions

Effective dashboards answer questions such as:

• Is the system healthy?  
• Are applications responding normally?  
• Are resources approaching limits?

### Local testing accelerates platform development

Developing dashboards and alerts locally using Docker Desktop or Minikube enables rapid iteration before deploying to cloud environments like EKS.

---

# Outcome

This project demonstrates how organizations can implement a **production-style Kubernetes observability platform** that provides:

• real-time infrastructure monitoring  
• application performance visibility  
• automated alerting for operational incidents  

Together, these capabilities allow platform teams to maintain **reliable and observable cloud-native systems**.

---

# Technologies Used

Kubernetes  
Prometheus  
Grafana  
Alertmanager  
Helm  
ArgoCD  
MongoDB  
Docker Desktop Kubernetes