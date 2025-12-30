# Lessons Learned – Minikube + ArgoCD + Ingress + MongoDB

This project surfaced several classic but important Kubernetes and GitOps lessons. Nothing was fundamentally broken — the issues were about wiring, discovery, and configuration boundaries.

1. ArgoCD App-of-Apps: How It Really Works
Key Insight

ArgoCD does not deploy folders — it deploys Application CRDs only.

Lessons

The root App-of-Apps only scans for kind: Application

Deployments, Services, Secrets, etc. are ignored unless wrapped by an Application

A “Healthy & Synced” root app does not mean child apps exist

Required Structure
apps/dev/
├── web-app/
│   └── application.yaml
├── payment-app/
│   └── application.yaml
└── token/
    └── application.yaml


Each service must have its own application.yaml.

2. App-of-Apps Discovery Requires Directory Recursion
Root Cause

ArgoCD defaults to:

directory.recurse = false

What That Means

ArgoCD only checks the top-level folder

It will not descend into subfolders

Child apps are silently skipped (no errors)

Fix (Mandatory)
source:
  path: apps/dev
  directory:
    recurse: true

Lesson

If child apps live in subfolders, directory recursion must be enabled.

3. Service → Pod Port Mapping Is Critical
Common Failure Pattern

App listens on 8080

Service forwards to 80

Result: 502 / 503 / connection refused

Correct Rule
Ingress port     → Service port
Service targetPort → Container port

Correct Example
ports:
  - port: 80
    targetPort: 8080

Lesson

Services don’t guess ports — you must wire them explicitly.

4. Ingress Requires Explicit ingressClassName
Root Cause

Ingress existed but was not claimed by any controller

Why

Kubernetes no longer assumes a default ingress controller

Minikube + ingress-nginx requires explicit binding

Fix
spec:
  ingressClassName: nginx

Lesson

If an Ingress has no class, no controller will serve it.

5. MongoDB Authentication Belongs in Secrets, Not ConfigMaps
What Went Wrong

App tried to resolve mongodb

DNS resolution failed

Mongo client timed out and crashed the pod

Proper Pattern

ConfigMap → connection structure

Secret → credentials

# ConfigMap
DB_URL=mongodb://user:password@payment-mongo:27017/db

# Secret
MONGO_USER
MONGO_PASSWORD

Lesson

ConfigMaps = structure
Secrets = identity & credentials

6. Crash Loops Often Start After the App Starts
Important Observation

App logged: listening on port 3000

Then crashed later due to DB failure

Lesson

A pod starting successfully does not mean it is healthy.

This is why:

Readiness probes matter

External dependencies must be validated early

7. Ingress Errors Are Usually Downstream, Not Ingress Bugs
Observed Errors

502 Bad Gateway

503 Service Temporarily Unavailable

Actual Causes

Service targetPort mismatch

Missing ingressClassName

Backend pod crashing

Lesson

Ingress errors usually mean backend wiring is wrong, not that NGINX is broken.

8. ArgoCD Being “Healthy” Can Be Misleading
Why This Happens

ArgoCD reports health of what it sees

If it sees nothing, it still reports success

Lesson

Always validate with:

kubectl get applications -n argocd


Not just the UI status.

9. Minikube Behaves Like Production (If You Treat It Right)
What This Setup Achieved

Namespace isolation

Ingress-based routing

GitOps reconciliation

App-of-Apps orchestration

Lesson

Minikube is not “toy Kubernetes” — misconfigurations fail exactly like EKS.

10. Final Mental Model (Interview-Ready)

The issues were not code bugs.
They were configuration discovery boundaries:

ArgoCD didn’t recurse

Services didn’t map ports

Ingress wasn’t claimed

Secrets weren’t injected

Once the control plane wiring matched the runtime behavior, the system stabilized immediately.

One-Sentence Summary

Every failure came from Kubernetes doing exactly what it was told — just not what was assumed.