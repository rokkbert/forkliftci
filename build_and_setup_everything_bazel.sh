#!/bin/sh

./build_forklift_bazel.sh

./deploy_local_forklift_bazel.sh

./k8s-deploy-kubevirt.sh

. ./grant_permissions.sh

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
