Executive GitOps Dashboard (What Leadership Cares About)

This dashboard connects Git → ArgoCD → Kubernetes → MongoDB.

You’ll build it once, reuse forever.

🎯 Dashboard Sections & Queries
🔹 GitOps Control Plane
Panel	Query
Total Apps	count(argocd_app_info)
Healthy Apps	count(argocd_app_info{health_status="Healthy"})
Synced Apps	count(argocd_app_info{sync_status="Synced"})
Drifted Apps	count(argocd_app_info{sync_status!="Synced"})
🔹 Delivery Signal
Panel	Query
Sync Success (1h)	increase(argocd_app_sync_total{phase="Succeeded"}[1h])
Sync Failures (1h)	increase(argocd_app_sync_total{phase="Failed"}[1h])
🔹 Platform Health
Panel	Query
MongoDB Up	mongodb_up
Pod Restarts	increase(kube_pod_container_status_restarts_total[1h])
Nodes Ready	count(kube_node_status_condition{condition="Ready",status="true"})
🔹 Workloads
Panel	Query
Running Pods	count(kube_pod_status_phase{phase="Running"})
Failed Pods	count(kube_pod_status_phase{phase="Failed"})
🧠 Why this dashboard is powerful

Tells one story

Explains impact

Ideal for:

demos

interviews

platform reviews

CTO conversations