# SSO (Single Sign On with Kubernetes)

This guide will help you to set up SSO for k8s.

We're going to use Dex as an OIDC provider for k8s authentication, you can use any other OIDC providers
with the similar deployment steps.


## Prerequisites

- local k8s running from https://github.com/teracyhq-incubator/teracy-dev-entry-k8s#how-to-use

- `kubectl` and `helm` is installed on your host machine and follow: https://github.com/teracyhq-incubator/teracy-dev-k8s#accessing-kubernetes-api

- [cert-manager](cert-manager.md) to set up a CA cluster issuer


## Domain Aliases

We're going to deploy dex (accounts.k8s.local) and dex-k8s-authenticator (login.k8s.local) helm charts,
so make sure to configure these domain aliases (see https://github.com/teracyhq-incubator/teracy-dev-entry-k8s#domain-aliases).

We can use the following config by adding into the `teracy-dev-entry/config_override.yaml` file:

```
nodes:
  - _id: "0"
    plugins:
      - _id: entry-hostmanager
        options:
          _ua_aliases: # set domain aliases for the master node
            - accounts.k8s.local
            - login.k8s.local
```

## accounts.k8s.local Dex Deployment

Create the "dex" namespace to deploy the app:

```bash
$ kubectl create namespace dex
```

Create the `accounts-k8s-local-tls` TLS certificate for ingress:

```bash
$ cd ~/k8s-dev/extensions/teracy-dev-k8s/docs/sso
$ kubectl apply -f accounts-k8s-local-cert.yaml --namespace=dex
certificate.certmanager.k8s.io/accounts-k8s-local created
```

You should see the following output:

```bash
$ kubectl -n dex describe certificates accounts-k8s-local
Name:         accounts-k8s-local
Namespace:    dex
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"certmanager.k8s.io/v1alpha1","kind":"Certificate","metadata":{"annotations":{},"name":"accounts-k8s-local","namespace":"dex...
API Version:  certmanager.k8s.io/v1alpha1
Kind:         Certificate
Metadata:
  Creation Timestamp:  2018-12-19T16:43:17Z
  Generation:          1
  Resource Version:    1749581
  Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/dex/certificates/accounts-k8s-local
  UID:                 2fa27113-03ad-11e9-896d-08002781145e
Spec:
  Common Name:  accounts.k8s.local
  Dns Names:
    accounts.k8s.local
  Issuer Ref:
    Kind:  ClusterIssuer
    Name:  ca-cluster-issuer
  Organization:
    Dex
  Secret Name:  accounts-k8s-local-tls
Status:
  Conditions:
    Last Transition Time:  2018-12-19T16:43:19Z
    Message:               Certificate issued successfully
    Reason:                CertIssued
    Status:                True
    Type:                  Ready
Events:
  Type    Reason      Age   From          Message
  ----    ------      ----  ----          -------
  Normal  IssueCert   23s   cert-manager  Issuing certificate...
  Normal  CertIssued  23s   cert-manager  Certificate issued successfully
```

[Create a GitHub OAuth app](https://developer.github.com/apps/building-oauth-apps/creating-an-oauth-app/)
to get the client id and client secret, make sure the redirect uri (https://accounts.k8s.local/callback)
matches the `Authorization callback URL`.

Export variables for setting:

```bash
$ export GITHUB_CLIENT_ID= #fill in here
$ export GITHUB_CLIENT_SECRET= # fill in here
# can use: export AUTHENTICATOR_SECRET=$(openssl rand -base64 24) && echo $AUTHENTICATOR_SECRET
$ export AUTHENTICATOR_SECRET=tVi5untH4I8OBy42mf5DOpTf0Q04N+bQ # use this for the example only
```

Then deploy it:

```bash
$ cd ~/k8s-dev/extensions/teracy-dev-k8s/docs/sso
$ helm upgrade --install --namespace dex dex stable/dex -f dex.yaml --set=config.connectors[0].config.clientID=$GITHUB_CLIENT_ID --set=config.connectors[0].config.clientSecret=$GITHUB_CLIENT_SECRET --set=config.staticClients[0].secret=$AUTHENTICATOR_SECRET
Release "dex" does not exist. Installing it now.
NAME:   dex
LAST DEPLOYED: Thu Dec 20 00:04:33 2018
NAMESPACE: dex
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME  AGE
dex   47s

==> v1beta2/Deployment
dex  47s

==> v1beta1/Ingress
dex  47s

==> v1/Pod(related)

NAME                  READY  STATUS             RESTARTS  AGE
dex-7f4c644fb6-f5xjq  0/1    ContainerCreating  0         47s

==> v1/Secret

NAME  AGE
dex   47s

==> v1/ServiceAccount
dex  47s

==> v1beta1/ClusterRoleBinding
dex  47s


NOTES:
1. Get the application URL by running these commands:
  https://accounts.k8s.local/
```

Trust the self signed generated CA certificate file (`workspace/certs/k8s-local-ca.crt`) by
following https://github.com/teracyhq-incubator/teracy-dev-certs#how-to-trust-the-self-signed-ca-certificate


After that, `https://accounts.k8s.local/.well-known/openid-configuration` should display information
like the following content:

```
{
  "issuer": "https://accounts.k8s.local",
  "authorization_endpoint": "https://accounts.k8s.local/auth",
  "token_endpoint": "https://accounts.k8s.local/token",
  "jwks_uri": "https://accounts.k8s.local/keys",
  "response_types_supported": [
    "code"
  ],
  "subject_types_supported": [
    "public"
  ],
  "id_token_signing_alg_values_supported": [
    "RS256"
  ],
  "scopes_supported": [
    "openid",
    "email",
    "groups",
    "profile",
    "offline_access"
  ],
  "token_endpoint_auth_methods_supported": [
    "client_secret_basic"
  ],
  "claims_supported": [
    "aud",
    "email",
    "email_verified",
    "exp",
    "iat",
    "iss",
    "locale",
    "name",
    "sub"
  ]
}
```

## Configure the K8S API Server

Set the ansible configuration through the `teracy-dev-k8s`'s `host_vars` in the
`workspace/teracy-dev-entry/config_override.yaml` file:

```
teracy-dev-k8s:
  ansible:
    host_vars:
      kube_oidc_auth: "True"
      kube_oidc_url: https://accounts.k8s.local
      kube_oidc_client_id: k8s-authenticator
      kube_oidc_ca_file: "{{ kube_cert_dir }}/dex-ca.pem"
      kube_oidc_username_claim: email
      kube_oidc_groups_claim: groups
```

- Copy the `certs/k8s-local-ca.crt` file to the `/etc/kubernetes/ssl/` diretory in the master server:

```
$ vagrant ssh
$ sudo cp /vagrant/workspace/certs/k8s-local-ca.crt /etc/kubernetes/ssl/dex-ca.pem
```

After that, `$ vagrant reload --provision --provision-with teracy-dev-k8s` should activate the OIDC
auth for the k8s cluster.


## login.k8s.local Dex K8s Authenticator Deployment

- Clone [this repo](https://github.com/mintel/dex-k8s-authenticator) into the `workspace` directory:

```
$ cd ~/k8s-dev/workspace
$ git clone https://github.com/mintel/dex-k8s-authenticator.git
$ cd dex-k8s-authenticator
$ helm inspect values charts/dex-k8s-authenticator > dex-k8s-authenticator.yaml
```

Fill in the details to the `dex-k8s-authenticator.yaml` file, for example:

```yaml
# Default values for dex-k8s-authenticator.

# Deploy environment label, e.g. dev, test, prod
global:
  deployEnv: dev

replicaCount: 1

image:
  repository: mintel/dex-k8s-authenticator
  tag: latest
  pullPolicy: Always

dexK8sAuthenticator:
  port: 5555
  debug: false
  web_path_prefix: /
  #logoUrl: http://<path-to-your-logo.png>
  #tlsCert: /path/to/dex-client.crt
  #tlsKey: /path/to/dex-client.key
  clusters:
  - name: k8s
    short_description: "k8s.local"
    description: "k8s.local cluster"
    client_secret: tVi5untH4I8OBy42mf5DOpTf0Q04N+bQ
    issuer: https://accounts.k8s.local
    k8s_master_uri: https://172.17.8.101:6443
    client_id: k8s-authenticator
    redirect_uri: https://login.k8s.local/callback/k8s
    k8s_ca_pem: |
      -----BEGIN CERTIFICATE-----
      MIIC/DCCAeSgAwIBAgIJAKEqzW7I7aQcMA0GCSqGSIb3DQEBCwUAMBIxEDAOBgNV
      BAMMB2t1YmUtY2EwIBcNMTgxMDI3MDY0NDE5WhgPMjExODEwMDMwNjQ0MTlaMBIx
      EDAOBgNVBAMMB2t1YmUtY2EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
      AQDcjNqu0P5RrQzPlM7GAojrPyLDxQRY1BbEQr2aXklS8lv7yiUK2ANchZvA454O
      ZIutuHJxf55q4eCY87nqWGeKAy8HGXUPxvFHnn/hiY9JlPi1n12SojUu2p8TOy6q
      J4aDkgboJuMu37+k03VZ7hCRbQcCsxoEZsW8xKM4SJY6dkdZNRRoRI8RUoVyLBdS
      wXSZW1J12LJtGbYCjHhgfLVDx1bt4e/j7W6cQzeSBJE3nqQiM6hvyYqytPqbsa9P
      ZSrtanow55PaCUsLK7dkpRvZrqh/7Fuc97ePdov+G8QxRJ4ej0c1ap2HMifekAz0
      BAi/8JF2I66coC/LK0qNDvu1AgMBAAGjUzBRMB0GA1UdDgQWBBQdrscGKIDLKP5h
      MHqzJINYTty7BjAfBgNVHSMEGDAWgBQdrscGKIDLKP5hMHqzJINYTty7BjAPBgNV
      HRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQCyhKRePcqAlFFh0BunqVvo
      bgf8MT27zF295/3FrENomhMJgAXUSQ81c2trMpr6ZVLj75WlcNL59nWDtpeKuwj8
      b4yqt1msFhQX/ReLSvBjHe2aiFupRnPZCOQDn1XublAHT1ig4DWeb5W/EI8Y7gce
      tkJbvSS6Q84gCqRJXxVeQaaPL4I/NpVX2B0Y0Hgc0W8uHhzxetnncSGhJNhITecc
      CjjN3K59bh4lb6Qq3wId5m5JkwqdLq6BYG5DtHwP/h4y/Tw+kyrhX9DMFIARwVUg
      YLpHoGp4lyDY4JF3dxd92PzUOG+zp5jQh1+UHYK4oycLQ8djU/ojtBVPwQuEKmPL
      -----END CERTIFICATE-----

service:
  type: ClusterIP
  port: 5555

  # For nodeport, specify the following:
  #   type: NodePort
  #   nodePort: <port-number>

ingress:
  enabled: true
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  path: /
  hosts:
    - login.k8s.local
  tls:
   - secretName: login-k8s-local-tls
     hosts:
       - login.k8s.local

resources: {}
  # We usually recommend not to specify default resources and to leave this as a conscious
  # choice for the user. This also increases chances charts run on environments with little
  # resources, such as Minikube. If you do want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  # limits:
  #  cpu: 100m
  #  memory: 128Mi
  # requests:
  #  cpu: 100m
  #  memory: 128Mi

caCerts:
  enabled: true
  # secrets: {}
  # Array of Self Signed Certificates
  # cat CA.crt | base64 -w 0
  #
  #     name: The internal k8s name of the secret we create. It's also used in
  #     the volumeMount name. It must respect the k8s naming convension (avoid
  #     upper-case and '.' to be safe).
  #
  #     filename: The filename of the CA to be mounted. It must end in .crt for
  #     update-ca-certificates to work
  #
  #     value: The base64 encoded value of the CA
  #
  secrets:
    - name: k8s-local-ca
      filename: k8s-local-ca.crt
      value: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZCRENDQXV5Z0F3SUJBZ0lKQUlCZlRlUVM1aWpSTUEwR0NTcUdTSWIzRFFFQkN3VUFNQmN4RlRBVEJnTlYKQkFNTURHczRjeTFzYjJOaGJDMWpZVEFlRncweE9ERXdNamd4T0RVek1qRmFGdzB5TkRBME1Ua3hPRFV6TWpGYQpNQmN4RlRBVEJnTlZCQU1NREdzNGN5MXNiMk5oYkMxallUQ0NBaUl3RFFZSktvWklodmNOQVFFQkJRQURnZ0lQCkFEQ0NBZ29DZ2dJQkFLamN2T2Njekd4SmVqZEtyVFpzTllFVlAxYkVvQUxkTUZXbnRUZGwyNllyUEVGTk8vYloKYTlIQ200NUlWM1kzK1JFcFhDQnlhM0xIRFpJZDh4MmlQOW5pSzV0ek0waGNxR2R6djBtT05UNllhWGdjdndQcApSM3ZpTlNVNzF0dk05QTk2MmVRdkQ4eXBaVkNVcStYZ2tIU0tVSXVTbG5ydEZIUm1waVZYbVc0Yk01WE84UVVFCjV0Q3ZNR20xNE5OVTVSRnRXRHczZVdSTkRqaTRUWmpod0YvNzFVbW4xeE1abTJ0dW41S25tSGVtR09DVWN0UlgKc25IZnpiMlBkYVFkaVhMd2QvbkFLUnpQUVEyVDluZEZ3REl4QzhOMEZjK1JrN3dCWFhuRnlDaEhJbXMzUUdoNAplR1VxcHVJc2psZjZ6RzA1ODFpcG9vSDk2Yk9HTVo2d3drc1M5bmFsM1JuS3NqejRuK1loM0Roay91dlhqT2xvClF3QWc4OXNCNzZSQ0E3WDl1eFJJRkhpNVB3Y0t3Q0QwMWxnK0Vhb1A5bUE0MVlRbzQ2SlNERGJKdVRJUWZ5R0kKOFAveVpOZVI0WVozWUU1dmNrV3h4Y3h5V0wwSHlLSUtTQnJtenJQbzlFTEZUWEJuZXgrUkxLTGdXTjFPMk9PRgpqZFgrVzZTVVJJT05pL3B4aUVNS3BQYnNzWkV2N2hYbGpRTEcyMUQwd1FvUHBzR1BTWG9waHlGY0lUYzV3RFA0Ci9PRVp1RFJ0d0JrV1dQa3BpUFNZRVdLSlhocjJuZ0VaSUQ3aXpFdjRiY1ZrejBtUWowWU5IYlBsZ2tJN3dFM0gKVU9kOXgzWW1RYVVWTDF3TzZZSmdQVlJZeG9CZ2hVamNVcFBtbmZXbHdsR0VkZjdkV0pOZ1A5QXJBZ01CQUFHagpVekJSTUIwR0ExVWREZ1FXQkJSUmRqbSt0b0E2YVpOTW9tbVYycHNrTnNRaW9EQWZCZ05WSFNNRUdEQVdnQlJSCmRqbSt0b0E2YVpOTW9tbVYycHNrTnNRaW9EQVBCZ05WSFJNQkFmOEVCVEFEQVFIL01BMEdDU3FHU0liM0RRRUIKQ3dVQUE0SUNBUUI0b2FGYkhtYWJmTXlWeG55QXI5Um5Ed254akc3U2UzeER5NTdza3dhck9hNVZXUUN2aVJSNwpIR0JZN0x1OElQd1U2OTRXTDR0K05wYm1VUFhINEtlQzdyeGZ1ZzNrTW1adnVoNUZYWWJMdjNPTERXZUpYL2pHCk8wSDV6T1lkSWliNDFrSGE5Yzd2R2xqUHpvcG1ON3J0Zk41SlU4QkxOY1ptVXpheFhmaXlrQjRucHRXMUl5M2wKQTU5UVQ5dWxPRVBodEhKSFl2ZUR2anVXTUpvSW81Z0c1cjZSeEJRVi9hRmd5Y1hENkNrSm9sUlVaOEZtUkt0eQpZVFFBK1VsTC9nSzczb0JFQTNRZmZKSkE2c0hSMitrRFV3clgwYUQ4QUFYcCtNSXNWU1hhcHI1b0R4dkxpZzlWCkFmWlV3V0Z0b1FUbkEzNmVtZ1RncnhqdXJxcnpsdEFNbm9wMXNxdFBNRTNnVXlobUtGYjJQcmxTNnRmWFkwRWYKSmR2aE9xVk11cVRzbWhSd1ZyS2NkTmpEcXhLNGZBWnM0RlE4QTdhT3MxTTBPU0gwT1lrUktYcDRVN0ZlMEp6awpkU01wVEt1M0NwS2I1MnRyVHM2TUV6NGQ3aElRVU5LWityeXJQclpmZTdoTXo3MjgwYVY1aUNKZ0d5blJVdzh1ClVtcVltaUJORG9XOEpnTFJxKzIwbC9BTlFkV0FyQWRhMDR6YjVUcnFBWW5sVHdTdkFnSmMyUGFzYWlZUFM0bnUKT2FJenRQV0l3dFJRcVlKbEU2SzhmNk9RdXBBMi9NODdua1VVR0tMNXZ6QU9mTHB3S3VGS0Rud0owcGFIVlNxdAorRVZ5dWhzOUhQc2lqKzYzMWh1VkZhZUd6U1NVVG1wVGtRcGNaa2JqTEo1K0drK0lqZm15VVE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
  #- name: ca-cert2
  #  filename: ca2.crt
  #  value: DS1tFA1......X2F


nodeSelector: {}

tolerations: []

affinity: {}
```

The `k8s_ca_pem` content is retrieved from the `inventory/artifacts/admin.conf` file by using base64
decoding of the `certificate-authority-data`. For example: `$ echo '<data>' | base64 --decode`

The `k8s-local-ca.crt` value is encoded by base64 from the `certs/k8s-local-ca.crt` file:

```bash
$ cd ~/k8s-dev/workspace/certs
$ cat k8s-local-ca.crt | base64
```

Create the `login-k8s-local-tls` TLS certificate for ingress:

```bash
$ cd ~/k8s-dev/extensions/teracy-dev-k8s/docs/sso
$ kubectl apply -f login-k8s-local-cert.yaml --namespace=dex
certificate.certmanager.k8s.io/login-k8s-local created
```


Then execute the following command:

```bash
$ cd ~/k8s-dev/workspace/dex-k8s-authenticator
$ helm upgrade --install --namespace dex login charts/dex-k8s-authenticator -f dex-k8s-authenticator.yaml
```


After that, open https://login.k8s.local for the k8s login instruction.


Remember to assign roles for the authenticated users to access the k8s cluster, for example:

```
$ kubectl create clusterrolebinding hoatle-cluster-admin --user=hoatle@k8s.local --clusterrole=cluster-admin
```


## SSO with k8s dashboard

//TODO: https://github.com/teracyhq-incubator/teracy-dev-k8s/issues/33

## SSO with docker registry

//TODO: https://github.com/teracyhq-incubator/teracy-dev-k8s/issues/34


## References

- https://github.com/dexidp/dex
- https://kubernetes.io/docs/reference/access-authn-authz/authentication/
- https://github.com/mintel/dex-k8s-authenticator
- https://www.keycloak.org/
