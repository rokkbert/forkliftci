# Overview

This document explains the current work-in-progress status of migrating from
[vcsim](https://github.com/vmware/govmomi/tree/master/vcsim). For more
background on the whole bazel/kind/forklift-process please see the other
documents in this repo, esp.
[BUILD_AND_INSTALL_FORKLIFT_WITH_BAZEL_ON_KIND.md](BUILD_AND_INSTALL_FORKLIFT_WITH_BAZEL_ON_KIND.md).
Later, when everything works reliably, these steps should be integrated into
one script (or maybe two, one for CI and one for manual execution).

# Step by step instructions

## Build vcsim image without TLS

This needs to be done only once. Get the
[Dockerfile](https://github.com/vmware/govmomi/blob/master/Dockerfile.vcsim) for vcsim. 
Change the last line to disable TLS:

    CMD ["-l", "0.0.0.0:8989", "-tls=false"]

Build the image: 

    docker build -f Dockerfile.vcsim -t localhost:5001/vcsim .

This image will be pushed to the local registry which will be started soon.


## Increase some limits

    sudo sysctl fs.inotify.max_user_watches=524288
    sudo sysctl fs.inotify.max_user_instances=512

Some containers won't work if these limits are lower (which might be the
default).


## Start cluster + build + deployment

Run the script build_and_setup_everything_bazel_manually.sh
It will take a few minutes.

## Push vcsim image to local registry

After the script from the last step printed "Creating cluster "kind" ...",
which happens pretty fast, you can push the image to the now running
registry:

    docker push localhost:5001/vcsim

The script will hang later, until that is done, because it won't be able to
find the image and the vcsim-pod will go into status ImagePullBackOff when
the script reaches "service/vcsim created".


## Check deployment progress

You can use the usual commands to track the deployment progress:

    kubectl get pods -A

    kubectl get -n konveyor-forklift providers

(The latter needs to show a vsphere-provider which should be Ready.)


## Start migration

Apply the script manual_deploy_migration_vsphere.yml to start the migration
of the simulated VM named DC0_H0_VM0:

    kubectl apply -f manual_deploy_migration_vsphere.yml


## Check migration progress

    kubectl get migration -n konveyor-forklift test-1664181665570-v -o yaml

The current state is, that this will run until it hits this error:

  'Unable to connect to vddk data source: connect_uri: nbd_connect_uri: handshake:
          server has no export named '''': No such file or directory'

It is unknown, why it is asking for an export with an empty name.

The log of the forklift-controller:

    kubectl logs -n konveyor-forklift `kubectl get pods -n konveyor-forklift | grep controller | cut -f 1 -d ' '` main

The log of the CDI:

    kubectl logs -n cdi `kubectl get pods -n cdi | grep deploy | cut -f 1 -d ' '`

This will show the same error as above.

The log of the importer-pod (will start a bit later than the others):

    kubectl logs `kubectl get pods | grep importer-test | cut -f 1 -d ' '`


## Other debug help

To talk to the vcsim you can use
[govc](https://pkg.go.dev/github.com/vmware/govmomi/govc).
For example, after creating a port forwarding to the vcsim container:

    kubectl port-forward deploy/vcsim 8989:8989 -n konveyor-forklift

Set variables and explore:

    export GOVC_INSECURE=true
    export GOVC_URL=http://user:pass@127.0.0.1:8989/sdk
    govc ls -json  /DC0/datastore/LocalDS_0 | jq
    govc ls -json  /DC0/vm/DC0_H0_VM0 | jq

To see how the vsphere-provider looks in forklift:

    export CLUSTER=`kind get kubeconfig | grep server | cut -d ' ' -f6`
    export TOKEN=`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-id}'|base64 -d`.`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-secret}'|base64 -d`

    curl -k "$CLUSTER/apis/forklift.konveyor.io/v1beta1/namespaces/konveyor-forklift/providers/vsphere-provider" --header "Authorization: Bearer $TOKEN"

Or, better, start port forwarding to the inventory container:

    kubectl port-forward -n konveyor-forklift service/forklift-inventory 9090:8080

And query it directly:

    export TOKEN=`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-id}'|base64 -d`.`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-secret}'|base64 -d`
    curl -k "http://localhost:9090/providers/vsphere/" --header "Authorization: Bearer $TOKEN" -v | jq


The problematic step seems to be
[nbdkit](https://github.com/libguestfs/nbdkit). You should see its arguments
with ps (the process is owned by user qemu), when the migration reaches the
abovementioned error.
