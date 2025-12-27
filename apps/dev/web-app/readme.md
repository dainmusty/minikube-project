# To install argocd on a minikube
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:80
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
qRouIH5ZYHyvgTwR

# To test the web-app
Port forward using its container port number (8081)
kubectl port-forward svc/argocd-server -n argocd 8081:80


# Minikube is not able to pull images from dockerhub thus you have to preload the image
Web App
1. docker pull dainmusty/phone-store:latest     # listens on port 80
2. minikube image load dainmusty/phone-store:latest

Token App
1. docker pull dainmusty/effulgencetech-nodejs-img:tag          # listens on port 8080
2. minikube image load dainmusty/effulgencetech-nodejs-img:tag
3. kubectl port-forward svc/argocd-server -n argocd 8081:80


# this installs nginx alb controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

kubectl apply -f ingress.yaml

http://web.apps.local
http://token.apps.local
http://payment.apps.local
