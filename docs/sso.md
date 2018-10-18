# SSO (Single Sign On with Kubernetes)

This guide will help you to set up SSO for k8s. You should set up a local k8s to test this on local
by following: https://github.com/teracyhq-incubator/teracy-dev-entry-k8s#how-to-use

We're going to use Dex as a OIDC provider for k8s authentication, you can use any other OIDC providers
with the similar deployment steps.


## Domain Aliases

We're going to deploy dex (auth.k8s.local) and dex-k8s-authenticator (login.k8s.local) helm charts,
so make sure to configure these domain aliases (see https://github.com/teracyhq-incubator/teracy-dev-entry-k8s#domain-aliases).


## auth.k8s.local Dex Deployment

```
$ mkdir -p ~/k8s-dev/workspace/sso
$ cd ~/k8s-dev/workspace/sso
$ helm inspect values stable/dex > dex.yaml
```

And the adjust the `dex.yaml` file, for example:

```
# Default values for dex
# This is a YAML-formatted file.
# Declare name/value pairs to be passed into your templates.
# name: value

image: quay.io/dexidp/dex
imageTag: "v2.11.0"
imagePullPolicy: "IfNotPresent"

inMiniKube: false

nodeSelector: {}

replicas: 1

# resources:
  # limits:
    # cpu: 100m
    # memory: 50Mi
  # requests:
    # cpu: 100m
    # memory: 50Mi

ports:
  - name: http
    containerPort: 8080
    protocol: TCP
#   nodePort: 32080
  - name: grpc
    containerPort: 5000
    protocol: TCP

service:
  type: ClusterIP
  annotations: {}

ingress:
  enabled: true
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  path: /
  hosts:
    - auth.k8s.local
  tls:
    - secretName: dex-web-server-tls
      hosts:
        - auth.k8s.local

extraVolumes: []
extraVolumeMounts: []

certs:
  image: gcr.io/google_containers/kubernetes-dashboard-init-amd64
  imageTag: "v1.0.0"
  imagePullPolicy: "IfNotPresent"
  web:
    create: true
    activeDeadlineSeconds: 300
    caDays: 10000
    certDays: 10000
    altNames:
      - auth.k8s.local
    altIPs: {}
    secret:
      tlsName: dex-web-server-tls
      caName: dex-web-server-ca
  grpc:
    create: true
    activeDeadlineSeconds: 300
    altNames:
      - auth.k8s.local
    altIPs: {}
    secret:
      serverTlsName: dex-grpc-server-tls
      clientTlsName: dex-grpc-client-tls
      caName: dex-grpc-ca

env: []

rbac:
  # Specifies whether RBAC resources should be created
  create: true

serviceAccount:
  # Specifies whether a ServiceAccount should be created
  create: true
  # The name of the ServiceAccount to use.
  # If not set and create is true, a name is generated using the fullname template
  name:

config:
  issuer: https://auth.k8s.local
  storage:
    type: kubernetes
    config:
      inCluster: true
  logger:
    level: debug
  web:
    http: 0.0.0.0:8080
#   tlsCert: /etc/dex/tls/https/server/tls.crt
#   tlsKey: /etc/dex/tls/https/server/tls.key
  grpc:
    addr: 0.0.0.0:5000
    tlsCert: /etc/dex/tls/grpc/server/tls.crt
    tlsKey: /etc/dex/tls/grpc/server/tls.key
    tlsClientCA: /etc/dex/tls/grpc/ca/tls.crt
  connectors:
    - type: github
      id: github
      name: GitHub
      config:
        clientID: <fill_in_here>
        clientSecret: <fill_in_here>
        redirectURI: https://auth.k8s.local/callback
#      org: kubernetes
  oauth2:
    skipApprovalScreen: true

  staticClients:
    - id: k8s-authenticator
      redirectURIs:
        - 'https://login.k8s.local/callback/k8s'
      name: 'k8s Authenticator App'
      secret: tVi5untH4I8OBy42mf5DOpTf0Q04N+bQ
  enablePasswordDB: false
```

Create a GitHub OAuth app to fill in the client id and client secret, make sure the matching redirect uri.

You can use `$ openssl rand -base64 24` to create a secret.

Then deploy it:


```
$ kubectl create namespace dex # if dex namespace not created yet
$ helm upgrade --install --namespace dex dex stable/dex -f dex.yaml
```

After that, `https://auth.k8s.local/.well-known/openid-configuration` should display info like the
following content:

```
{
  "issuer": "https://auth.k8s.local",
  "authorization_endpoint": "https://auth.k8s.local/auth",
  "token_endpoint": "https://auth.k8s.local/token",
  "jwks_uri": "https://auth.k8s.local/keys",
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

`$ kubectl -n dex get configmaps dex-web-server-ca -o yaml` to see the dex CA root certifcate that
the k8s api server must trust and the dex client apps must trust when the self-signed certificate is
used for the dex deployment. Create the `sso/dex-ca.pem` file from the config map data above.


## Configure the k8s api server

Set the ansible config, through the `workspace/inventory/group_vars/k8s-cluster/k8s-cluster.yaml` or
though the teracy-dev-k8s host_vars configuration on the
`workspace/teracy-dev-entry/config_override.yaml` file:

```
teracy-dev-k8s:
  ansible:
    host_vars:
      kube_oidc_auth: "True"
      kube_oidc_url: https://auth.k8s.local
      kube_oidc_client_id: k8s-authenticator
      kube_oidc_ca_file: "{{ kube_cert_dir }}/dex-ca.pem"
      kube_oidc_username_claim: email
      kube_oidc_groups_claim: groups
```

- Copy the `sso/dex-ca.pem` file to the master server at `/etc/kubernetes/ssl/`:

```
$ vagrant ssh
$ sudo cp /vagrant/workspace/sso/dex-ca.pem /etc/kubernetes/ssl/
```

After that, `$ vagrant reload --provision` should enable the oidc auth for the k8s cluster.


## login.k8s.local Dex K8s Authenticator Deployment

- Clone [this repo](https://github.com/mintel/dex-k8s-authenticator) into the `workspace` directory:

```
$ cd ~/k8s-dev/workspace
$ git clone https://github.com/mintel/dex-k8s-authenticator
$ cd dex-k8s-authenticator
$ helm inspect values charts/dex-k8s-authenticator > dex-k8s-authenticator.yaml
```

Fill in the details to the `dex-k8s-authenticator.yaml` file, for example:

```
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
    issuer: https://auth.k8s.local
    k8s_master_uri: https://172.17.8.101:6443
    client_id: k8s-authenticator
    redirect_uri: https://login.k8s.local/callback/k8s
    k8s_ca_pem: |
      -----BEGIN CERTIFICATE-----
      MIIC/DCCAeSgAwIBAgIJAOYV7rSZyhi6MA0GCSqGSIb3DQEBCwUAMBIxEDAOBgNV
      BAMMB2t1YmUtY2EwIBcNMTgxMDEwMDM0MjU4WhgPMjExODA5MTYwMzQyNThaMBIx
      EDAOBgNVBAMMB2t1YmUtY2EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
      AQDtZvSTO/rk906V5k0UxsZOQGEvDWGYgp4CYwZ+ejlud/l9uWLDfogocFG9jsli
      POMa+I8G3mcqWl1rM7LN4oMMdsL3Pjhr74fn40QX5tysKiAjEFX9rLqVV7s9cH4j
      Nq8rvq4xzM+rkPWSlWN1EbE48lZJMe7G9+7de0eGf+9pAgjhY7v8SYsNHyWcWby7
      R+KlHI1oXAZzDlN4iZJEHkZ5x/BKKJ4Rwctlaf6fIyUL6WAR9wcrhNhZ30X3HQ+O
      n0UOt9Bee0rNsejI10yA17unmlZ1cb0lcFbC2lIdd8i+08OUTM0pjTxxPjNRKv12
      5LdxOhh1TWgUkQ2SY5TNBl9ZAgMBAAGjUzBRMB0GA1UdDgQWBBR3Gt1/HBGGq/TJ
      fNnVV07zbQlrwDAfBgNVHSMEGDAWgBR3Gt1/HBGGq/TJfNnVV07zbQlrwDAPBgNV
      HRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBkyA1F9VAhTGUejiRFuX/I
      JULV4Y6xQmVD7AAzK/Yes6NHKR6uEKsCrftJoWHAS3PyjE7JCimwL1gg9KWctzYA
      0PdlllA4cMi/47ew+3U6KG2WRpo1ncJxA7tvcd0N4XeudZKq0u7Dpwex5vbZYJj1
      KDVbnerIvEbUvl0wXhB3REVefAbo3EtJQkBttam9MSj4Rbxj2Wwbtqfz65Ht+/kl
      z0JA2bJPq0PsdXdv7xgGDvzoGUvv4wkLiSEQYeKYYvOC+b7nv1nNb/X+5/UOdgO4
      opBmyqYo+tMXW/Z8dKVifTVTacqLrGu4GoxgDWdsDXT+6X3fPjXnworfzABzDUGA
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
   - secretName:
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
    - name: dex-ca
      filename: dex-ca.crt
      value: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM5VENDQWQyZ0F3SUJBZ0lKQU45K2hEeWdub3RkTUEwR0NTcUdTSWIzRFFFQkN3VUFNQkV4RHpBTkJnTlYKQkFNTUJtUmxlQzFqWVRBZUZ3MHhPREV3TVRJeE1USTFNemhhRncwME5qQXlNamN4TVRJMU16aGFNQkV4RHpBTgpCZ05WQkFNTUJtUmxlQzFqWVRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTVl5CkNCSWdpYVI5VTRqWi83MW9na0NXc2orWFRwQ2dLMmtCNFZhbHRIVWd5dStwMU43SWxIYXI4SUJPakN0ZWtqd2MKUVc1aS9BK0VLS1hYZWZ0VEd6TVY2d0R5UGVYclpnRHNQTlh0MXRqcVhDS1hEZ0dIU1p6SmMzVm1tcW1WMFpnLwp3aVhSMTlMQXZudEU3ODZoWGNLOHE2RHRUZjJkZkkvTEkrVnBOWWc0S0hjWmMxMmFVZkZpL3IvcHo0YTlmak5BCk5jTFBZd0tKTWxGVFA5c2tPamFBbm1nbVpYQ3EvSmR6K2dsMlVNWHgwU1IzNk1BQy9jZm1RYkFrNlZsd3BmdisKODd0Y1FpSlhjSmh1THFkb042WS9CNDB5MTV0MGo5VUk4Z01aaG9FS1ljYXZXNG9vYzZNaVRSMnRkTkg3U3NrVQpXWDJKbnVXNk1rYlg5L09SQ0lzQ0F3RUFBYU5RTUU0d0hRWURWUjBPQkJZRUZGUUdkZlQ2eXVGdnRmV3FSOTU2CllTb0xRVmhnTUI4R0ExVWRJd1FZTUJhQUZGUUdkZlQ2eXVGdnRmV3FSOTU2WVNvTFFWaGdNQXdHQTFVZEV3UUYKTUFNQkFmOHdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBSXdTc3diaG8xcXpvaHlablhldGVTM0cwL1ppOVFhRApkRWlzZjhuWkJDU1dCWVp2Z1lkeVg0UlA1VkVRVFBtREZ0SlpEaDA5cHkvTkZEMUFOTHFyTENoa0d2V3JtdTNJCmlOYUlWcnNtU2pMd09YeW04Z1VSYjUzWGxnY3pEc3RRTVVsajVCZlpHdk5SOGdpN3FOcHE1OXpTUVNqTnJDb3gKL2pCd1gxZDlMM0xDcW5aSHJkUWs5d2Q4RUpDU0xvS0pSQnorRjVIeG9DbERkMitydUc2K2dWSENEUTRPUGF4MwozeXNJM2U3V1Q1ZXArRGY3VEd6VVk2SjFqUHp0M2VUaDVsWTRBV1pycHFsVTg2VlQrVzFWUEs0eGc2N1REY3krCnJ6NjdweFN2cHZNVjcvMkZpL1ZNb0lCL1Zjd1BtSW4yemZPaE9nayt1ZlVsc0pib0dER1RPclk9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
  #- name: ca-cert2
  #  filename: ca2.crt
  #  value: DS1tFA1......X2F

nodeSelector: {}

tolerations: []

affinity: {}
```

The `k8s_ca_pem` content is retrieved from the `inventory/artifacts/admin.conf` file by using base64
decoding of the `client-certificate-data`. For example: `$ echo '<data>' | base64 --decode`

The `dex-ca.crt` value is base64 encoded from the `dex-ca.pem` file.

After that:

```
helm upgrade --install --namespace dex login charts/dex-k8s-authenticator -f dex-k8s-authenticator.yaml
```

then open https://login.k8s.local for the k8s login instruction.


Remember to assign roles for the authenticated users to access the k8s cluster, for example:

```
$ kubectl create clusterrolebinding hoatle-cluster-admin --user=hoatle@k8s.local --clusterrole=cluster-admin
```


## References

- https://github.com/dexidp/dex
- https://kubernetes.io/docs/reference/access-authn-authz/authentication/
- https://github.com/mintel/dex-k8s-authenticator
- https://www.keycloak.org/
