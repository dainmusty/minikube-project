Payment Application on Kubernetes (EKS / Minikube)

This repository demonstrates a production-grade microservice deployment on Kubernetes using MongoDB with authentication, Ingress with TLS, and GitOps via ArgoCD App-of-Apps.

It also documents a real-world debugging incident and the lessons learned from resolving it.

1️⃣ Architecture Overview
High-Level Architecture
                    ┌───────────────┐
                    │    Browser    │
                    └───────┬───────┘
                            │ HTTPS (TLS)
                            ▼
                  ┌──────────────────────┐
                  │   Ingress Controller │
                  │ (NGINX / ALB)         │
                  └─────────┬────────────┘
                            │
                            ▼
              ┌────────────────────────────┐
              │ payment-app Service         │
              │ (ClusterIP :80)             │
              └─────────┬──────────────────┘
                        │
                        ▼
              ┌────────────────────────────┐
              │ payment-app Pod             │
              │ (Node.js / Spring / etc.)   │
              └─────────┬──────────────────┘
                        │ MongoDB Auth
                        ▼
              ┌────────────────────────────┐
              │ MongoDB Service             │
              │ (ClusterIP :27017)          │
              └─────────┬──────────────────┘
                        ▼
              ┌────────────────────────────┐
              │ MongoDB Pod                 │
              │ Auth enabled                │
              │ Persistent Volume           │
              └────────────────────────────┘

2️⃣ Kubernetes Resource Breakdown
Namespaces

payment-app – Application + database

argocd – GitOps controller

cert-manager – TLS automation

3️⃣ MongoDB: Production-Grade Authentication
❌ What NOT to Do

Hardcode DB credentials in Deployment YAML

Use unauthenticated MongoDB in production

✅ Correct Setup
MongoDB Credentials → Kubernetes Secret
apiVersion: v1
kind: Secret
metadata:
  name: mongo-secret
  namespace: payment-app
type: Opaque
data:
  MONGO_INITDB_ROOT_USERNAME: <base64>
  MONGO_INITDB_ROOT_PASSWORD: <base64>

MongoDB Connection URL → ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongo-config
  namespace: payment-app
data:
  DB_URL: mongodb://payment-mongo:27017

App Deployment (Correct Reference)
env:
- name: DB_URL
  valueFrom:
    configMapKeyRef:
      name: mongo-config
      key: DB_URL

- name: DB_USERNAME
  valueFrom:
    secretKeyRef:
      name: mongo-secret
      key: MONGO_INITDB_ROOT_USERNAME

- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mongo-secret
      key: MONGO_INITDB_ROOT_PASSWORD

✅ Result

Credentials are encrypted at rest

App and DB are decoupled

Works with GitOps (no secrets in Git)

4️⃣ Ingress + TLS (cert-manager)
Ingress Definition
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: payment-app
  namespace: payment-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - payment.apps.local
    secretName: payment-app-tls
  rules:
  - host: payment.apps.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: payment-app
            port:
              number: 80

cert-manager Flow

Ingress created

cert-manager detects annotation

ACME challenge issued

TLS cert stored as Secret

HTTPS enabled automatically

5️⃣ ArgoCD App-of-Apps (GitOps)
Why App-of-Apps?

One root application

Multiple child apps

Declarative, scalable, clean Git structure

Folder Structure
k8s/
├── bootstrap/
│   └── root-app.yaml
└── apps/
    └── dev/
        └── payment-app/
            ├── deployment.yaml
            ├── service.yaml
            ├── ingress.yaml
            ├── mongo.yaml
            ├── secret.yaml
            └── configmap.yaml

Root Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: finapp
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: main
    path: k8s/apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

Benefits

One command bootstraps everything

Drift detection

Rollbacks via Git

6️⃣ The Incident (Interview-Ready Explanation)
🔴 Problem

Ingress existed

Service existed

Pod was running

But:

kubectl get endpoints payment-app
NAME          ENDPOINTS
payment-app   <none>

🔍 Root Cause

The Deployment did not correctly reference:

MongoDB connection URL

MongoDB credentials

As a result:

App container crashed or never became Ready

No Ready pods → No endpoints

Ingress had nothing to route to

🛠️ Fix

Properly split:

Sensitive data → Secrets

Non-sensitive config → ConfigMaps

Correct env.valueFrom references in Deployment

✅ Outcome
kubectl get endpoints payment-app
NAME          ENDPOINTS
payment-app   10.x.x.x:80


Ingress immediately started routing traffic.

7️⃣ Key Lessons Learned
Kubernetes Networking

Ingress → Service → Endpoints → Pods

No endpoints = broken chain

Configuration Management

Secrets for credentials

ConfigMaps for URLs & config

Never hardcode secrets

Debugging Order (Golden Rule)

Pod status

Readiness probes

Endpoints

Service selectors

Ingress rules

GitOps Discipline

ArgoCD will keep retrying broken manifests

Fix must be in Git, not kubectl edit

8️⃣ Production Readiness Checklist

✅ MongoDB authentication
✅ TLS enabled
✅ GitOps deployment
✅ Namespaced isolation
✅ No secrets in Git
✅ Scalable architecture
✅ Interview-ready explanation

9️⃣ How to Explain This in an Interview (Short Version)

“The issue wasn’t Ingress or Service. Kubernetes had no endpoints because the application pod wasn’t ready. The root cause was misconfigured environment variables for MongoDB authentication. Once I correctly separated secrets and configmaps and referenced them in the deployment, the pod became ready, endpoints were created, and ingress routing immediately worked.”

🔥 Final Note

What you built here is not beginner Kubernetes.

This demonstrates:

Real-world debugging

Secure configuration

GitOps maturity

Production architecture thinking