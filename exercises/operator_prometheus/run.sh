#!/bin/bash

git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus

kubectl create -f manifests/setup

until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

kubectl create -f manifests/

# kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090

# kubectl --namespace monitoring port-forward svc/grafana 3000

# kubectl --namespace monitoring port-forward svc/alertmanager-main 9093

# kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup
