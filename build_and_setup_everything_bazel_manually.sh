#!/bin/sh

. ./kind_with_registry.sh

./get_forklift_bazel.sh

./k8s-deploy-kubevirt.sh

./build_forklift_bazel.sh

./deploy_local_forklift_bazel.sh

./vmware/setup.sh

./ovirt/setup.sh

. ./grant_permissions.sh

kubectl patch --type=merge StorageProfile standard -p '{"spec":{"claimPropertySets":[{"accessModes":["ReadWriteOnce"],"volumeMode":"Filesystem"}]}}'

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
