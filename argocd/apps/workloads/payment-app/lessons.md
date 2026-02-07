Payment App on Kubernetes – Lessons Learned

This document captures the key lessons learned while deploying and debugging a multi-service payment application on Kubernetes using Deployments, Services, Ingress, ConfigMaps, Secrets, and ArgoCD.

1. Ingress 503 / 502 Errors Are Usually Backend Issues
Symptoms

Browser shows:

503 Service Temporarily Unavailable
nginx


Or:

502 Bad Gateway


Ingress appears healthy:

kubectl get ingress

Root Cause

NGINX Ingress was working correctly, but had no healthy backend to route traffic to.

Key Lesson

A 503 or 502 from NGINX almost always means:

No endpoints

Pod crashing

Application error (not an Ingress issue)

2. Service Selectors Must Match Pod Labels Exactly
Problem

The Service existed, but:

kubectl get endpoints payment-app
# <none>

Root Cause

Service selector:

selector:
  app: payment-app


Pod label:

labels:
  app: payment-web   # mismatch

Fix

Ensure Deployment labels = Service selectors:

labels:
  app: payment-app

Key Lesson

If endpoints are empty, Ingress will fail, even if Pods are running.

3. Ingress Must Point to the Correct Service Name
Problem

Ingress backend:

service:
  name: payment-app


But actual Service:

payment-web

Result

Ingress showed:

payment-app:80 ()

Fix

Rename Service or update Ingress backend to match.

Key Lesson

Ingress → Service name must match exactly, or NGINX has no upstream.

4. Internal Ports vs External Ports Matter
Correct Pattern

App listens on 3000

Service exposes 80

Ingress routes 80

ports:
  - port: 80
    targetPort: 3000

Key Lesson

Ingress talks to Service ports, not container ports.

5. Blank UI ≠ Ingress Problem
Symptom

App loads

Page is completely white

No visible error

Root Cause

Frontend JavaScript depended on:

fetch("/get-profile")


That API failed because MongoDB connection was broken.

Key Lesson

A blank UI usually means:

Backend API failed

JS error in browser console

Database connection issue

Always check:

Browser console

Pod logs

6. MongoDB Connection Failed Due to Wrong Hostname
Error
MongoTimeoutError: getaddrinfo EAI_AGAIN mongodb

Root Cause

App tried to connect to:

mongodb


But Kubernetes Service name was:

payment-mongo

Fix

Use the Service name as the hostname:

mongodb://payment-mongo:27017

Key Lesson

In Kubernetes, Service name = DNS hostname

7. Secrets and ConfigMaps Must Be Wired Correctly
Correct Pattern
ConfigMap (non-sensitive)
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongo-config
data:
  DB_URL: mongodb://payment-mongo:27017

Secret (sensitive)
apiVersion: v1
kind: Secret
metadata:
  name: mongo-secret
type: Opaque
data:
  mongo-user: <base64>
  mongo-password: <base64>

Deployment
env:
  - name: USER_NAME
    valueFrom:
      secretKeyRef:
        name: mongo-secret
        key: mongo-user
  - name: USER_PWD
    valueFrom:
      secretKeyRef:
        name: mongo-secret
        key: mongo-password
  - name: DB_URL
    valueFrom:
      configMapKeyRef:
        name: mongo-config
        key: DB_URL

Key Lesson

If Secrets or ConfigMaps are not correctly referenced, the app will fail silently.

8. How to Debug Kubernetes Apps Systematically
Golden Debug Order

kubectl get pods

kubectl logs <pod>

kubectl get svc

kubectl get endpoints

kubectl describe ingress

Test inside pod:

wget http://localhost:3000

Key Lesson

Kubernetes almost always tells you the answer — you just have to ask the right object.

9. ArgoCD Was Not the Problem 😄

ArgoCD correctly reported:

Missing resources

Failed syncs

Invalid Ingress definitions

Key Lesson

ArgoCD is a truth mirror, not the cause of the problem.

Final Outcome ✅

Ingress routing works

Backend API works

MongoDB connection works

Frontend renders correctly

App accessible via:

http://payment.apps.local

Final Takeaway

Kubernetes issues are rarely Kubernetes issues.

They are usually:

Label mismatches

Wrong service names

Broken environment variables

Application configuration problems