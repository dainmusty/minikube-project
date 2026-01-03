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


apiVersion: v1
kind: Service
metadata:
  name: payment-mongo
  namespace: payment-app
spec:
  selector:
    app: payment-mongo
  ports:
    - port: 27017
      targetPort: 27017
  type: ClusterIP
so for the payment-mongo-statefulset.yaml, at the cluster section you put "none". is it the same as mine above? mine doesn't have none, does it matter? what is the difference between a deployment and statefulset again, I know stateful sets are preferred are by databases.
apiVersion: v1
kind: Service
metadata:
  name: payment-mongo
  namespace: payment-app
spec:
  selector:
    app: payment-mongo
  ports:
    - port: 27017
      targetPort: 27017
  clusterIP: None   # REQUIRED for StatefulSet


Great questions — this is exactly the right time to lock these concepts in.
I’ll answer this in a clear, side-by-side, no-hand-waving way, because this is core Kubernetes knowledge (and very interviewable).

1️⃣ Is clusterIP: None the same as your current Service?
❌ No — they are not the same, and yes, it matters for a StatefulSet.
Your current Service
type: ClusterIP


Kubernetes auto-assigns a virtual IP, like:

payment-mongo → 10.96.123.45


All traffic goes to that single virtual IP, then kube-proxy load-balances.

StatefulSet Service (Headless)
clusterIP: None


This creates a headless service.

There is:

❌ No virtual IP

✅ Direct DNS entries for each pod

Example DNS entries:

payment-mongo-0.payment-mongo.payment-app.svc.cluster.local
payment-mongo-1.payment-mongo.payment-app.svc.cluster.local


This is mandatory for StatefulSets.

🔑 Why this matters for MongoDB

MongoDB needs:

Stable network identity

Stable hostname

Stable storage

A headless service provides stable DNS per pod, which Mongo relies on for:

Replica sets

Primary elections

Reconnection after restarts

➡️ Without clusterIP: None, StatefulSet networking breaks.

2️⃣ Can MongoDB still work without clusterIP: None?
Setup	Works?	Safe?
Deployment + ClusterIP	✅	❌ Not production
StatefulSet + ClusterIP	⚠️	❌ Wrong
StatefulSet + Headless Service	✅	✅ Correct

You might get Mongo running without it, but:

Replica sets will fail

DNS names won’t be stable

Scaling breaks

3️⃣ Deployment vs StatefulSet (Clear Mental Model)
Deployment (Stateless workloads)

Think:

“I don’t care which pod handles the request.”

Characteristics:

Pods are identical

Pod names change on restart

Storage is shared or ephemeral

Pods can be replaced freely

Perfect for:

Web apps

APIs

Workers

Frontends

Example:

payment-app-7c9d8c6f9c-abc12
payment-app-7c9d8c6f9c-xyz98

StatefulSet (Stateful workloads)

Think:

“Each pod has an identity and its own data.”

Characteristics:

Fixed pod names: payment-mongo-0

Ordered startup/shutdown

One PVC per pod

Stable DNS names

Predictable restarts

Perfect for:

MongoDB

PostgreSQL

MySQL

Kafka

Elasticsearch

4️⃣ Why Databases Prefer StatefulSets (Interview Answer)

Databases require stable storage and stable network identities.
StatefulSets guarantee predictable pod names, dedicated persistent volumes, and ordered startup.

This makes them suitable for leader election, replication, and recovery, which Deployments cannot guarantee.

5️⃣ Which Service Should YOU Use?
If using Deployment
type: ClusterIP

If using StatefulSet (recommended)
clusterIP: None

6️⃣ Final Recommendation for Your Setup

Since you already:

Use Mongo auth

Use PVC

Are building a portfolio / interview-ready project

👉 Switch to StatefulSet + Headless Service

Final Mongo Service (Correct)
apiVersion: v1
kind: Service
metadata:
  name: payment-mongo
  namespace: payment-app
spec:
  clusterIP: None
  selector:
    app: payment-mongo
  ports:
    - port: 27017
      targetPort: 27017

7️⃣ Quick Self-Test (Good Sign You Understand)

You now know:

Why clusterIP: None exists

Why Deployments are wrong for databases

Why StatefulSets need headless services

Why PVCs attach per pod

That’s senior-level Kubernetes understanding 💪