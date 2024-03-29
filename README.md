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

a. start the shell

```
❯ oc rsh deployment/pebble
sh-5.1$
```

b. check the cluster dir. 

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
❯ oc apply -f 03-clusterissuer.yaml
clusterissuer.cert-manager.io/pebble-http01 created
```

12. You should see the `ClusterIssuer` as `READY=True`.

```
❯ oc get clusterissuer
NAME            READY   AGE
pebble-http01   True    102s
```

13. Create the `Certificate`, you will have to update your dnsNames entry to match a dnsName hosted under `apps.*`.

```
cat << EOF | oc apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cert-03e
spec:
  dnsNames:
  - e03.apps.numt-ocp-9c91.ocp.local
  issuerRef:
    kind: ClusterIssuer
    name: pebble-http01
  secretName: cert-03-secrete
EOF
```

14. Check the `Certificate,Order,Route` and optionally the Challenge and CertificateRequest.

```
❯ oc get certificate,order
NAME                                  READY   SECRET           AGE
certificate.cert-manager.io/cert-01   False   cert-01-secret   25s

NAME                                              STATE     AGE
order.acme.cert-manager.io/cert-01-1-2002363495   pending   25s
```

Once the Order is complete, you will have your Certificate Ready=True.

### Troubleshooting

You can grab the logging for Pebble.

```
❯ oc logs -n pebble -l name=pebble
Pebble 2024/02/08 16:40:38 Pulled a task from the Tasks queue: &va.vaTask{Identifier:acme.Identifier{Type:"dns", Value:"e03.XT.local"}, Challenge:(*core.Challenge)(0xc0004c3cc0), Account:(*core.Account)(0xc0004abec0)}
Pebble 2024/02/08 16:40:38 Starting 3 validations.
Pebble 2024/02/08 16:40:38 Attempting to validate w/ HTTP: http://e03.XT.local:30501/.well-known/acme-challenge/XT-4
Pebble 2024/02/08 16:40:38 Attempting to validate w/ HTTP: http://e03.XT.local:30501/.well-known/acme-challenge/XT-4
Pebble 2024/02/08 16:40:38 Attempting to validate w/ HTTP: http://e03.XT.local:30501/.well-known/acme-challenge/XT-4
Pebble 2024/02/08 16:40:38 POST /authZ/ -> calling handler()
Pebble 2024/02/08 16:40:38 authz XT set INVALID by completed challenge XT
Pebble 2024/02/08 16:40:38 order XT set INVALID by invalid authz XT
Pebble 2024/02/08 16:40:41 POST /authZ/ -> calling handler()
Pebble 2024/02/08 16:40:41 POST /my-order/ -> calling handler()
```

You can check the status of the certificate using: 

```
❯ oc get certificate,route,challenge,order,certificaterequest
NAME                                  READY   SECRET           AGE
certificate.cert-manager.io/cert-01   True    cert-01-secret   3m24s

NAME                                 HOST/PORT                                       PATH   SERVICES     PORT          TERMINATION        WILDCARD
route.route.openshift.io/pebble-rt   pebble-rt-pebble.apps.X.ocp.local          pebble-svc   pebblehttps   passthrough/None   None

NAME                                              STATE   AGE
order.acme.cert-manager.io/cert-01-1-2068076300   valid   25s

NAME                                           APPROVED   DENIED   READY   ISSUER          REQUESTOR                                         AGE
certificaterequest.cert-manager.io/cert-01-1   True                True    pebble-test-x   system:serviceaccount:cert-manager:cert-manager   25s
```