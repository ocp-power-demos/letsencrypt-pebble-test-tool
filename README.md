# letsencrypt-pebble-test-tool

This is a *TEST* and *DEMO* tool only.
It is unsupported.

> A miniature version of Boulder, Pebble is a small RFC 8555 ACME test server not suited for a production certificate authority. 

[letsencrypt/pebble](https://github.com/letsencrypt/pebble/) is used for testing ACME and Certificate Manager. This project facilitates building a [ubi9](https://catalog.redhat.com/software/containers/ubi9/go-toolset/61e5c00b4ec9945c18787690?architecture=amd64&image=6571697c39a638623d7ab4a6) image.

The Pebble tool is [Mozilla Public License Version 2.0](https://github.com/letsencrypt/pebble/blob/main/LICENSE) and this project is [Apache License 2.0](https://github.com/ocp-power-demos/letsencrypt-pebble-test-tool/blob/main/LICENSE)

The image is available at [quay.io/powercloud/pebble-tool:pebble](https://quay.io/repository/powercloud/pebble-tool).

### Setup and Build Image

1. Install on Linux

```
dnf install -y make git podman
```

2. Setup the namespace

```
❯ oc apply -f 00-ns.yaml 
project.project.openshift.io/pebble created
```

3. Switch Project

```
❯ oc project pebble
Now using project "pebble" on server "https://api.XYZ.ocp-multiarch.xyz:6443".
```

4. Setup the ConfigMap

```
❯ oc apply -f 01-cm.yaml 
configmap/pebble-config created
```

5. Setup the Deployment

```
❯ oc apply -f 02-pebble.yaml
deployment.apps/pebble configured
service/pebble-svc created
```