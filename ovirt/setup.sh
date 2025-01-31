#!/bin/sh

docker build ovirt/ -t localhost:5001/fakeovirt
docker push localhost:5001/fakeovirt

kubectl apply -f ovirt/fakeovirt_deployment.yml
while ! kubectl get deployment -n konveyor-forklift fakeovirt; do sleep 10; done
kubectl wait deployment -n konveyor-forklift fakeovirt --for condition=Available=True --timeout=180s

kubectl apply -f ovirt/forklift_provider.yml
