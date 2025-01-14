#!/bin/sh

go install sigs.k8s.io/kind@v0.15.0

mkdir -p /tmp/kind_storage
chmod 777 /tmp/kind_storage

kind create cluster --config kind-config.yaml

kubectl apply -f add_pv.yml

export CLUSTER=`kind get kubeconfig | grep server | cut -d ' ' -f6`
