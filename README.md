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

2. Build the image

```
make build
```

3. Push the image

```
make push
```

### Setup the HTTP01 Issuer

1. Setup the namespace

```
❯ oc apply -f 00-ns.yaml 
project.project.openshift.io/pebble created
```

2. Switch Project

```
❯ oc project pebble
Now using project "pebble" on server "https://api.XYZ.ocp-multiarch.xyz:6443".
```

3. Create the tls secret and key

```
❯ openssl req -x509 -newkey rsa:4096 -keyout pebble.key -out pebble.crt -sha256 -days 3650 -nodes -subj "/C=US/ST=MA/L=Boston/O=IBM/OU=PowerSystems/CN=pebble-svc.pebble.svc.cluster.local"
```

4. Create the namespace key/crt

```
❯ oc create secret tls pebble-tls --key="pebble.key" --cert="pebble.crt"
secret/pebble-tls created
```

7. Setup the ConfigMap

```
❯ oc apply -f 01-cm.yaml 
configmap/pebble-config created
```

8. Setup the Deployment

```
❯ oc apply -f 02-pebble.yaml
deployment.apps/pebble configured
service/pebble-svc created
```

9. Grab the Service details

```
❯ oc get svc
NAME         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                           AGE
pebble-svc   NodePort   172.30.250.95   <none>        30100:30100/TCP,30200:30200/TCP,30501:30501/TCP,30502:30502/TCP   2m35s
```

10. You should able to use pebble within the cluster.

```
❯ curl https://pebble-svc.pebble.svc.cluster.local:30100/dir -k
{
   "keyChange": "https://pebble-svc.pebble.svc.cluster.local:30100/rollover-account-key",
   "meta": {
      "externalAccountRequired": false,
      "termsOfService": "data:text/plain,Do%20what%20thou%20wilt"
   },
   "newAccount": "https://pebble-svc.pebble.svc.cluster.local:30100/sign-me-up",
   "newNonce": "https://pebble-svc.pebble.svc.cluster.local:30100/nonce-plz",
   "newOrder": "https://pebble-svc.pebble.svc.cluster.local:30100/order-plz",
   "revokeCert": "https://pebble-svc.pebble.svc.cluster.local:30100/revoke-cert"
}
```

Note, the ports are different.

11. Then use the following to generate the ClusterIssuer

```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: pebble-http01
spec:
  acme:
    server: https://pebble-svc.pebble.svc.cluster.local:30100/dir
    skipTLSVerify: true
    privateKeySecretRef:
      name: pebble-http01-account-key
    solvers:
    - http01:
        ingress:
          ingressClassName: openshift-default
```
