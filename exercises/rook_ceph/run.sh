#!/bin/bash

git clone https://github.com/rook/rook.git
cd rook
git checkout release-1.1
cd cluster/examples/kubernetes/ceph

kubectl create -f common.yaml
kubectl create -f operator.yaml

kubectl taint nodes $(kubectl get nodes | grep master | awk '{print $1}') node-role.kubernetes.io/master:NoSchedule-
