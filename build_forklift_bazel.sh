#!/bin/sh
echo "Running $0"

# Change the dir to FORKLIFT_DIR (default forklift)
cd ${FORKLIFT_DIR:-forklift}

export REGISTRY=localhost:5000
export REGISTRY_TAG=latest
export REGISTRY_ACCOUNT=""

bazel run push-forklift-controller
bazel run push-forklift-validation
bazel run push-forklift-operator
bazel run push-forklift-operator-bundle --action_env CONTROLLER_IMAGE=${REGISTRY}/forklift-controller:${REGISTRY_TAG} --action_env VALIDATION_IMAGE=${REGISTRY}/forklift-validation:${REGISTRY_TAG} --action_env OPERATOR_IMAGE=${REGISTRY}/forklift-operator:${REGISTRY_TAG}
bazel run push-forklift-operator-index --action_env REGISTRY=${REGISTRY} --action_env REGISTRY_TAG=${REGISTRY_TAG} --action_env OPM_OPTS="--use-http"
