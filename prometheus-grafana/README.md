# Grafana UI
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
http://localhost:3000

# Password
kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Add prometheus as a datasource
url required - http://monitoring-kube-prometheus-prometheus.monitoring.svc:9090


# Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
http://localhost:9090

How to Verify the Service Name (Optional)
kubectl get svc -n monitoring
monitoring-grafana
monitoring-kube-prometheus-prometheus
monitoring-kube-prometheus-alertmanager

echo "➕ Adding Prometheus Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true

i have some prometheus rules, how do i upload on the prometheus UI or i can do it via the CLI?
prometheus:
  prometheusSpec:
    additionalPrometheusRules:
      - name: custom-node-alerts
        groups:
          - name: node.rules
            rules:
              - alert: HighCPUUsage
                expr: >
                  100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle",job="node-exporter"}[5m])) * 100) > 80
                for: 2m
                labels:
                  severity: warning
                annotations:
                  summary: High CPU usage on {{ $labels.instance }}
                  description: CPU usage has been above 80% for more than 2 minutes.

              - alert: HighMemoryUsage
                expr: >
                  (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 80
                for: 2m
                labels:
                  severity: warning
                annotations:
                  summary: High memory usage on {{ $labels.instance }}
                  description: Memory usage has exceeded 80% for more than 2 minutes.

              - alert: NodeDown
                expr: up{job="node-exporter"} == 0
                for: 1m
                labels:
                  severity: critical
                annotations:
                  summary: Node {{ $labels.instance }} is down
                  description: Prometheus target {{ $labels.instance }} is unreachable (up == 0)

      - name: test-alert
        groups:
          - name: test.rules
            rules:
              - alert: TestAlert
                expr: vector(1)
                for: 1m
                labels:
                  severity: info
                annotations:
                  summary: This is a test alert
                  description: Firing to test Alertmanager and Slack integration


Great question — and this is an important distinction 👍
Short answer:

❌ You do NOT upload rules via the Prometheus UI
✅ You DO apply them via Kubernetes (CLI / Helm)

Since you’re using kube-prometheus-stack, Prometheus is managed, so rules are handled declaratively.

🔑 How Prometheus Rules Work (kube-prometheus-stack)

Prometheus does not persist rule uploads from the UI.
Instead, it watches Kubernetes resources:

PrometheusRule CRDs

Or Helm values (additionalPrometheusRules)

✅ OPTION 1 (BEST PRACTICE): Apply via CLI using PrometheusRule

This is the recommended and most common approach.

1️⃣ Convert Your Rules into a PrometheusRule CRD

Create a file called:

custom-alerts.yaml

✅ Correct Kubernetes Manifest (based on your rules)
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-node-alerts
  namespace: monitoring
  labels:
    release: monitoring
spec:
  groups:
    - name: node.rules
      rules:
        - alert: HighCPUUsage
          expr: |
            100 - (avg by(instance)(
              rate(node_cpu_seconds_total{mode="idle",job="node-exporter"}[5m])
            ) * 100) > 80
          for: 2m
          labels:
            severity: warning
          annotations:
            summary: High CPU usage on {{ $labels.instance }}
            description: CPU usage has been above 80% for more than 2 minutes.

        - alert: HighMemoryUsage
          expr: |
            (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
            / node_memory_MemTotal_bytes * 100 > 80
          for: 2m
          labels:
            severity: warning
          annotations:
            summary: High memory usage on {{ $labels.instance }}
            description: Memory usage has exceeded 80% for more than 2 minutes.

        - alert: NodeDown
          expr: up{job="node-exporter"} == 0
          for: 1m
          labels:
            severity: critical
          annotations:
            summary: Node {{ $labels.instance }} is down
            description: Prometheus target {{ $labels.instance }} is unreachable

    - name: test.rules
      rules:
        - alert: TestAlert
          expr: vector(1)
          for: 1m
          labels:
            severity: info
          annotations:
            summary: This is a test alert
            description: Firing to test Alertmanager and Slack integration

2️⃣ Apply the Rules via CLI
kubectl apply -f custom-alerts.yaml

3️⃣ Verify Prometheus Picked Them Up
Check CRD exists
kubectl get prometheusrules -n monitoring

Check in Prometheus UI

Go to Status → Rules

You should see:

HighCPUUsage

HighMemoryUsage

NodeDown

TestAlert

4️⃣ Verify Alertmanager (for TestAlert)
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093


Open:

http://localhost:9093


You should see TestAlert firing after ~1 minute.

✅ OPTION 2: Helm Values (additionalPrometheusRules)

This is ONLY if you want rules bundled into Helm lifecycle.

Example values.yaml
prometheus:
  prometheusSpec:
    additionalPrometheusRules:
      - name: custom-node-alerts
        groups:
          - name: node.rules
            rules:
              - alert: HighCPUUsage
                expr: 100 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100 > 80
                for: 2m


Apply with:

helm upgrade monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values.yaml


⚠️ Downside: slower iteration, less flexible than CRDs.

❌ What You CANNOT Do
Method	Supported?
Upload via Prometheus UI	❌ No
Paste rules into Grafana	❌ No
Edit Prometheus pod files	❌ No
kubectl exec + edit	❌ No

Prometheus is immutable in Kubernetes by design.

🧠 Best Practice Summary (What You Should Do)

✔ Use PrometheusRule CRDs
✔ Apply via kubectl
✔ Store rules in Git (GitOps-ready)
✔ Let Alertmanager handle routing
✔ Keep dashboards separate from alerts

i thought you said managing these files with kubectl is best practice, why don't we update the manifest below?
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-node-alerts
  namespace: monitoring....

and also where is this line   slack_api_url: $(SLACK_WEBHOOK_URL), if it is being referenced as variable, where is it defined?

Excellent questions — this is exactly the right instinct, and you’ve caught two very important nuances. Let’s clear them up cleanly.

1️⃣ PrometheusRule vs Alertmanager config (WHY we don’t put Slack there)

You are 100% correct that PrometheusRule manifests are managed with kubectl / GitOps.

But here’s the key distinction 👇

🔴 PrometheusRule is for WHEN to alert
🔵 Alertmanager config is for WHAT TO DO with alerts
Your manifest:
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule


This resource:

Defines alert conditions

Evaluated by Prometheus

Produces alerts with labels like:

severity

namespace

alertname

❌ It cannot:

Send Slack messages

Define routing

Group alerts

Silence alerts

That is by design.

🧠 Mental Model (Very Important)
PrometheusRule  →  Prometheus  →  Alertmanager  →  Slack / Email / PagerDuty
        (when)                     (where/how)


So we should update your PrometheusRule for:

Labels

Severity

Signal quality

But Slack routing never belongs there.

2️⃣ YES — managing PrometheusRule with kubectl IS best practice

Your existing manifest is already correct and should stay that way.

Example (unchanged, correct):

apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-node-alerts
  namespace: monitoring
spec:
  groups:
    - name: node.rules
      rules:
        - alert: HighCPUUsage
          expr: ...
          labels:
            severity: warning


✅ Apply with:

kubectl apply -f custom-node-alerts.yaml


This is GitOps-perfect.

3️⃣ Where does slack_api_url: $(SLACK_WEBHOOK_URL) actually come from?

This is the second excellent catch 👏
You’re right to ask: “Where is that variable defined?”

Short answer:

It comes from a Kubernetes Secret, injected into Alertmanager.

🔐 Correct, Explicit, No-Magic Explanation
Step 1: Define the Secret (THIS is where it lives)
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-slack
  namespace: monitoring
type: Opaque
stringData:
  SLACK_WEBHOOK_URL: https://hooks.slack.com/services/T000/B000/XXXX


Apply:

kubectl apply -f alertmanager-slack.yaml

Step 2: Tell Alertmanager to load this Secret

In kube-prometheus-stack, this is done via Helm values:

alertmanager:
  alertmanagerSpec:
    secrets:
      - alertmanager-slack


This causes Kubernetes to:

Mount the secret into the Alertmanager pod

Expose SLACK_WEBHOOK_URL as an environment variable

Step 3: Reference it in Alertmanager config

Now this line makes sense:

global:
  slack_api_url: $(SLACK_WEBHOOK_URL)


Alertmanager:

Reads env vars at runtime

Substitutes $(SLACK_WEBHOOK_URL)

Keeps secrets out of Git

✅ This is secure
✅ This is standard
✅ This is production-grade

4️⃣ Why we DON’T manage Alertmanager config with kubectl apply

You can, but with kube-prometheus-stack it’s intentionally abstracted.

❌ This will NOT work:
kubectl apply -f alertmanager-config.yaml


Because:

Alertmanager config is not a CRD

It’s a generated ConfigMap

Owned by Helm

Overwritten on every Helm upgrade

✅ Correct GitOps Control Points
Component	Managed by	Tool
PrometheusRule	You	kubectl / Git
Alertmanager routing	Helm values	Helm / ArgoCD
Slack secrets	Kubernetes Secret	kubectl / External Secrets
Dashboards	Grafana provisioning	Git

This separation is intentional and correct.

5️⃣ If you REALLY want Alertmanager config as YAML-only (no Helm)

There is a CRD-based approach:

apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig


But ⚠️:

More complex

Less documented

Helm values are still the most common in production

If you want, I can show that approach too, side-by-side.

✅ Final Takeaway (You were right)

✔ You should manage PrometheusRule with kubectl
✔ Slack routing does not belong in PrometheusRule
✔ slack_api_url comes from a Kubernetes Secret
✔ Alertmanager config is owned by Helm, not kubectl
✔ This design prevents config drift and secret leaks

kubectl delete servicemonitor argocd-service-monitor -n argocd
kubectl delete servicemonitor argocd-metrics -n monitoring
