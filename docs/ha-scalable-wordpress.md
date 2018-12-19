# High availability, scalable WordPress

Follow this guide to set up a high availability (HA) and scalable WordPress deployment on a k8s cluster.


## Prerequisites

- a k8s cluster available by following https://github.com/teracyhq-incubator/teracy-dev-entry-k8s#how-to-use

- [Rook storage service](rook-storage-service.md) to set up rook-ceph-block storage class by
  following https://rook.io/docs/rook/v0.8/block.html#provision-storage

- [cert-manager](cert-manager.md) to set up a CA cluster issuer


## MySQL Deployment

- Deploy the operator:

  ```bash
  $ cd ~/k8s-dev/extensions/teracy-dev-k8s/docs/ha-scalable-wordpress
  $ kubectl create namespace mysql-operator # create if not exists yet
  $ helm repo add presslabs https://presslabs.github.io/charts
  $ helm upgrade --install mysql-operator presslabs/mysql-operator --namespace=mysql-operator -f mysql-operator-override.yaml
  ```

  You should see the similar console output as follows:

  ```bash
  $ helm upgrade --install mysql-operator presslabs/mysql-operator --namespace=mysql-operator -f mysql-operator-override.yaml
  Release "mysql-operator" does not exist. Installing it now.
  NAME:   mysql-operator
  LAST DEPLOYED: Fri Dec 14 01:21:05 2018
  NAMESPACE: mysql-operator
  STATUS: DEPLOYED

  RESOURCES:
  ==> v1/Secret
  NAME                         AGE
  mysql-operator-orchestrator  0s

  ==> v1/ServiceAccount
  mysql-operator  0s

  ==> v1/Service
  mysql-operator-orchestrator           0s
  mysql-operator-orchestrator-headless  0s

  ==> v1beta2/Deployment
  mysql-operator  0s

  ==> v1/ConfigMap
  mysql-operator-orchestrator  0s

  ==> v1/ClusterRole
  mysql-operator  0s

  ==> v1beta1/ClusterRoleBinding
  mysql-operator  0s

  ==> v1/StatefulSet
  mysql-operator-orchestrator  0s

  ==> v1/Pod(related)

  NAME                             READY  STATUS             RESTARTS  AGE
  mysql-operator-687bd6b768-xg665  0/1    ContainerCreating  0         0s
  mysql-operator-orchestrator-0    0/1    ContainerCreating  0         0s


  NOTES:
  You can create a new cluster by issuing:

  cat <<EOF | kubectl apply -f-
  apiVersion: mysql.presslabs.org/v1alpha1
  kind: MysqlCluster
  metadata:
    name: my-cluster
  spec:
    replicas: 1
    secretName: my-cluster-secret
  ---
  apiVersion: v1
  kind: Secret
  metadata:
    name: my-cluster-secret
  type: Opaque
  data:
    ROOT_PASSWORD: $(echo -n "not-so-secure" | base64)
  EOF
  ```

  ```bash
  $ kubectl get pv
  NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                               STORAGECLASS      REASON   AGE
  pvc-593515aa-e714-11e8-aa03-08002781145e   2Gi        RWO            Delete           Bound    rook-nfs/nfs-ceph-claim                             rook-ceph-block            30d
  pvc-dab1fa69-ff03-11e8-abfb-08002781145e   1Gi        RWO            Delete           Bound    mysql-operator/data-mysql-operator-orchestrator-0   rook-ceph-block            1m
  ```

  ```bash
  $ kubectl -n mysql-operator get pods
  NAME                              READY   STATUS    RESTARTS   AGE
  mysql-operator-687bd6b768-xg665   1/1     Running   0          1m
  mysql-operator-orchestrator-0     1/1     Running   1          1m
  ```


- Create a MySQL cluster, for example:

  ```bash
  $ cd ~/k8s-dev/extensions/teracy-dev-k8s/docs/ha-scalable-wordpress
  $ kubectl create namespace wordpress # create if not exists yet
  $ kubectl apply -f mysql-secret.yaml --namespace=wordpress # create secret for the mysql-cluster.yaml
  $ kubectl apply -f mysql-cluster.yaml --namespace=wordpress # create a MySQL cluster
  ```

  Wait for a while (`$ kubectl -n wordpress get pods -w`) until all pods are ready with the following
  similar output:

  ```bash
  $ kubectl -n wordpress get pods
  NAME                 READY   STATUS    RESTARTS   AGE
  db-cluster-mysql-0   4/4     Running   2          1m
  db-cluster-mysql-1   4/4     Running   0          1m
  ```

  ```bash
  $ kubectl -n wordpress get services
  NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
  db-cluster-mysql          ClusterIP   10.233.19.221   <none>        3306/TCP            2m
  db-cluster-mysql-master   ClusterIP   10.233.38.122   <none>        3306/TCP            2m
  db-cluster-mysql-nodes    ClusterIP   None            <none>        3306/TCP,9125/TCP   2m
  ```

- Access the created MySQL cluster with the host as service names above and root password defined
  in the `mysql-secret.yaml` file (`admin` by default):

  ```bash
  $ kubectl run mysql-client --image=bitnami/wordpress:4.9.8 -it --rm --restart=Never --namespace=wordpress bash
  If you don't see a command prompt, try pressing enter.
  root@mysql-client:/# mysql -h db-cluster-mysql-master -u root -padmin
  Welcome to the MariaDB monitor.  Commands end with ; or \g.
  Your MySQL connection id is 261
  Server version: 5.7.23-24-log Percona Server (GPL), Release '24', Revision '57a9574'

  Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

  Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

  MySQL [(none)]>
  ```

- Create a database and user for the WordPress application:

  ```bash
  $ kubectl run mysql-client --image=bitnami/wordpress:4.9.8 -it --rm --restart=Never --namespace=wordpress bash
  If you don't see a command prompt, try pressing enter.
  root@mysql-client:/# mysql -h db-cluster-mysql-master -u root -padmin
  Welcome to the MariaDB monitor.  Commands end with ; or \g.
  Your MySQL connection id is 261
  Server version: 5.7.23-24-log Percona Server (GPL), Release '24', Revision '57a9574'

  Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

  Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

  MySQL [(none)]> CREATE DATABASE wordpress;
  Query OK, 1 row affected (0.01 sec)

  MySQL [(none)]> GRANT ALL ON wordpress.* TO wordpress@'%' IDENTIFIED BY 'mypass';
  Query OK, 0 rows affected, 1 warning (0.04 sec)

  MySQL [(none)]> FLUSH PRIVILEGES;
  Query OK, 0 rows affected (0.02 sec)
  MySQL [(none)]> exit
  Bye
  root@mysql-client:/# exit
  exit
  pod "mysql-client" deleted
  ```

  The database name (`wordpress`) with username (`wordpress`) and password (`mypass`) created above
  will be used for the WordPress application below.


## WordPress Deployment

- Create a `PersistentVolumeClaim` with `ReadWriteMany` (RWX) access modes so that we can deploy multiple
  WordPress containers sharing the same file system to access the shared resources:

  + Create a Rook `NFSServer`:

    ```bash
    $ cd ~/k8s-dev/extensions/teracy-dev-k8s/docs/ha-scalable-wordpress
    $ kubectl apply -f nfs-ceph.yaml
    ```

    You should see the following output:

    ```bash
    $ kubectl get nfsservers.nfs.rook.io -n rook-nfs
    NAME       AGE
    rook-nfs   1m
    ```

    ```bash
    $ kubectl -n rook-nfs get pods
    NAME         READY   STATUS    RESTARTS   AGE
    rook-nfs-0   1/1     Running   0          2m
    ```

  + Create a NFS volume:

    Find the NFS server address:

    ```bash
    $ echo NFS server: `kubectl -n rook-nfs get service -l app=rook-nfs -o jsonpath='{.items[0].spec.clusterIP}'`
    NFS server: 10.233.26.45
    ```

    Fill in the value `10.233.26.45`, for example, from the ouput above in to the
    `~/k8s-dev/extensions/teracy-dev-k8s/docs/ha-scalable-wordpress/nfs-pv.yaml` file and execute the following command:

    ```bash
    $ cd ~/k8s-dev/extensions/teracy-dev-k8s/docs/ha-scalable-wordpress
    $ kubectl apply -f nfs-pv.yaml
    persistentvolume/rook-nfs-pv created
    ```

    `$ kubectl get pv` should show the created `rook-nfs-pv` persistent volume:

    ```bash
    $ kubectl get pv
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                               STORAGECLASS      REASON   AGE
    pvc-2201adbc-ff05-11e8-abfb-08002781145e   1Gi        RWO            Delete           Bound       wordpress/data-db-cluster-mysql-0                   rook-ceph-block            39m
    pvc-3ac22548-ff05-11e8-abfb-08002781145e   1Gi        RWO            Delete           Bound       wordpress/data-db-cluster-mysql-1                   rook-ceph-block            38m
    pvc-b6ed2cf1-ff08-11e8-abfb-08002781145e   2Gi        RWO            Delete           Bound       rook-nfs/nfs-ceph-claim                             rook-ceph-block            13m
    pvc-dab1fa69-ff03-11e8-abfb-08002781145e   1Gi        RWO            Delete           Bound       mysql-operator/data-mysql-operator-orchestrator-0   rook-ceph-block            48m
    rook-nfs-pv                                2Gi        RWX            Retain           Available                                                       rook-nfs-sc                27s
    ```

  + Create a `PersistentVolumeClaim` with `ReadWriteMany` (RWX) access modes:

    ```bash
    $ cd ~/k8s-dev/extensions/teracy-dev-k8s/docs/ha-scalable-wordpress
    $ kubectl apply -f wordpress-pvc.yaml --namespace=wordpress
    persistentvolumeclaim/wp-app-nfs-pv-claim created
    ```

    You should see the following similar output:

    ```bash
    $ kubectl -n wordpress get pvc
    NAME                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
    data-db-cluster-mysql-0   Bound    pvc-2201adbc-ff05-11e8-abfb-08002781145e   1Gi        RWO            rook-ceph-block   43m
    data-db-cluster-mysql-1   Bound    pvc-3ac22548-ff05-11e8-abfb-08002781145e   1Gi        RWO            rook-ceph-block   42m
    wp-app-nfs-pv-claim       Bound    rook-nfs-pv                                2Gi        RWX            rook-nfs-sc       20s
    ```

    Test the created PVC:

    ```bash
    $ kubectl apply -f web-rc-pvc-test.yaml --namespace=wordpress
    ```

    ```bash
    $ kubectl -n wordpress get pods -w
    NAME                 READY   STATUS    RESTARTS   AGE
    db-cluster-mysql-0   4/4     Running   17         151m
    db-cluster-mysql-1   4/4     Running   15         150m
    nfs-web-dg87c        1/1     Running   0          55s
    ```

    ```bash
    $ kubectl -n wordpress exec -it nfs-web-dg87c bash # use the pod name displayed above
    root@nfs-web-dg87c:/# ls -la /usr/share/nginx/html/ # check the volume content
    total 36
    drwxr-xr-x 6 nobody 4294967294  4096 Dec 13 19:24 .
    drwxr-xr-x 3 root   root        4096 Nov 27 22:21 ..
    drwxr-xr-x 3 nobody 4294967294  4096 Dec 13 19:27 apache
    drwx------ 2 nobody 4294967294 16384 Dec 13 18:56 lost+found
    drwxr-xr-x 3 nobody 4294967294  4096 Dec 13 19:27 php
    drwxr-xr-x 3 nobody 4294967294  4096 Dec 13 20:32 wordpress
    root@nfs-web-dg87c:/# rm -rf /usr/share/nginx/html/* # clean up if you want
    root@nfs-web-dg87c:/# ls -la /usr/share/nginx/html/
    total 8
    drwxr-xr-x 2 nobody 4294967294 4096 Dec 13 21:03 .
    drwxr-xr-x 3 root   root       4096 Nov 27 22:21 ..
    root@nfs-web-dg87c:/# exit
    ```

- Create a TLS certificate:

  Make sure `ca-cluster-issuer` is available:

  ```bash
  $ kubectl get clusterissuers.certmanager.k8s.io
  NAME                AGE
  ca-cluster-issuer   3d
  ```

  Create a TLS certificate:

  ```bash
  $ cd ~/k8s-dev/extensions/teracy-dev-k8s/docs/ha-scalable-wordpress
  $ kubectl apply -f certificate.yaml --namespace=wordpress
  certificate.certmanager.k8s.io/wordpress-k8s-local created
  ```

  You should see the following output:

  ```bash
  $ kubectl -n wordpress describe certificates wordpress-k8s-local
  Name:         wordpress-k8s-local
  Namespace:    wordpress
  Labels:       <none>
  Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                  {"apiVersion":"certmanager.k8s.io/v1alpha1","kind":"Certificate","metadata":{"annotations":{},"name":"wordpress-k8s-local","namespace":"wo...
  API Version:  certmanager.k8s.io/v1alpha1
  Kind:         Certificate
  Metadata:
    Creation Timestamp:  2018-12-13T19:19:47Z
    Generation:          1
    Resource Version:    1624990
    Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/wordpress/certificates/wordpress-k8s-local
    UID:                 0e1a7b92-ff0c-11e8-abfb-08002781145e
  Spec:
    Common Name:  wordpress.k8s.local
    Dns Names:
      wordpress.k8s.local
    Issuer Ref:
      Kind:  ClusterIssuer
      Name:  ca-cluster-issuer
    Organization:
      WordPress
    Secret Name:  wordpress-k8s-local-tls
  Status:
    Conditions:
      Last Transition Time:  2018-12-13T19:19:50Z
      Message:               Certificate issued successfully
      Reason:                CertIssued
      Status:                True
      Type:                  Ready
  Events:
    Type    Reason      Age   From          Message
    ----    ------      ----  ----          -------
    Normal  IssueCert   2m9s  cert-manager  Issuing certificate...
    Normal  CertIssued  2m8s  cert-manager  Certificate issued successfully
  ```

  ```bash
  $ kubectl -n wordpress get secrets wordpress-k8s-local-tls
  NAME                      TYPE                DATA   AGE
  wordpress-k8s-local-tls   kubernetes.io/tls   2      2m
  ```

- Deploy the WordPress application:

  ```bash
  $ cd ~/k8s-dev/extensions/teracy-dev-k8s/docs/ha-scalable-wordpress
  $ helm upgrade --install wp-app stable/wordpress --namespace=wordpress -f wordpress-override.yaml
  ```

  Wait for a while (`$ kubectl -n wordpress get pods -w`) until all pods are ready with the following
  similar output:

  ```bash
  $ kubectl -n wordpress get pods
  NAME                              READY   STATUS    RESTARTS   AGE
  db-cluster-mysql-0                4/4     Running   17         2h
  db-cluster-mysql-1                4/4     Running   15         2h
  nfs-web-dg87c                     1/1     Running   0          13m
  wp-app-wordpress-b55949bc-jphc5   1/1     Running   1          5m
  ```

  ```bash
  $ kubectl -n wordpress logs -f wp-app-wordpress-b55949bc-jphc5 # use the pod name displayed above
  Welcome to the Bitnami wordpress container
  Subscribe to project updates by watching https://github.com/bitnami/bitnami-docker-wordpress
  Submit issues and feature requests at https://github.com/bitnami/bitnami-docker-wordpress/issues

  WARN  ==> You set the environment variable ALLOW_EMPTY_PASSWORD=yes. For safety reasons, do not use this flag in a production environment.
  nami    INFO  Initializing apache
  apache  INFO  ==> Reconfiguring PID file location...
  apache  INFO  ==> Configuring dummy certificates...
  nami    INFO  apache successfully initialized
  nami    INFO  Initializing php
  nami    INFO  php successfully initialized
  nami    INFO  Initializing mysql-client
  nami    INFO  mysql-client successfully initialized
  nami    INFO  Initializing libphp
  nami    INFO  libphp successfully initialized
  nami    INFO  Initializing wordpress
  wordpre INFO  WordPress has been already initialized, restoring...
  mysql-c INFO  Trying to connect to MySQL server
  mysql-c INFO  Found MySQL server listening at db-cluster-mysql-master:3306
  mysql-c INFO  MySQL server listening and working at db-cluster-mysql-master:3306
  wordpre INFO  Upgrading WordPress Database ...
  wordpre INFO 
  wordpre INFO  ########################################################################
  wordpre INFO   Installation parameters for wordpress:
  wordpre INFO     Persisted data and properties have been restored.
  wordpre INFO     Any input specified will not take effect.
  wordpre INFO   This installation requires no credentials.
  wordpre INFO  ########################################################################
  wordpre INFO 
  nami    INFO  wordpress successfully initialized
  INFO  ==> Starting wordpress... 
  [Thu Dec 13 21:12:38.761994 2018] [ssl:warn] [pid 112] AH01909: localhost:443:0 server certificate does NOT include an ID which matches the server name
  [Thu Dec 13 21:12:38.778150 2018] [ssl:warn] [pid 112] AH01909: localhost:443:0 server certificate does NOT include an ID which matches the server name
  [Thu Dec 13 21:12:39.040639 2018] [ssl:warn] [pid 112] AH01909: localhost:443:0 server certificate does NOT include an ID which matches the server name
  [Thu Dec 13 21:12:39.058510 2018] [ssl:warn] [pid 112] AH01909: localhost:443:0 server certificate does NOT include an ID which matches the server name
  [Thu Dec 13 21:12:39.201792 2018] [mpm_prefork:notice] [pid 112] AH00163: Apache/2.4.37 (Unix) OpenSSL/1.1.0f PHP/7.1.24 configured -- resuming normal operations
  [Thu Dec 13 21:12:39.201839 2018] [core:notice] [pid 112] AH00094: Command line: 'httpd -f /bitnami/apache/conf/httpd.conf -D FOREGROUND'
  10.233.64.1 - - [13/Dec/2018:21:12:40 +0000] "GET /wp-login.php HTTP/1.1" 200 1077
  ```

- Scale the WordPress application:

  ```bash
  $ helm upgrade --install wp-app stable/wordpress --namespace=wordpress -f wordpress-override.yaml --set=replicaCount=2
  ```

  You should see the following similar output:

  ```bash
  $ kubectl -n wordpress get pods
  NAME                              READY   STATUS    RESTARTS   AGE
  db-cluster-mysql-0                4/4     Running   17         2h
  db-cluster-mysql-1                4/4     Running   15         2h
  nfs-web-dg87c                     1/1     Running   0          18m
  wp-app-wordpress-b55949bc-2rdxm   1/1     Running   0          2m
  wp-app-wordpress-b55949bc-jphc5   1/1     Running   1          11m
  ```

## Domain Alias

- `wordpress.k8s.local` domain is configured in the `certificate.yaml` and `wordpress-override.yaml`
  file so you need to configure the domain alias to access it.

- Add the following configuration into the `workspace/teracy-dev-entry/config_override.yaml` file:

  ```yaml
    nodes:
      - _id: "0"
        plugins:
          - _id: "entry-hostmanager"
            options:
              _ua_aliases: # set domain aliases for the master node
                - "wordpress.k8s.local"
  ```

- Execute `$ vagrant hostmanger` to update the `hosts` file and then check the domain alias if it
  is working properly:

  ```bash
  $ ping wordpress.k8s.local
  PING wordpress.k8s.local (172.17.8.101): 56 data bytes
  64 bytes from 172.17.8.101: icmp_seq=0 ttl=64 time=0.438 ms
  64 bytes from 172.17.8.101: icmp_seq=1 ttl=64 time=0.706 ms
  64 bytes from 172.17.8.101: icmp_seq=2 ttl=64 time=0.409 ms
  64 bytes from 172.17.8.101: icmp_seq=3 ttl=64 time=0.237 ms
  ^C
  --- wordpress.k8s.local ping statistics ---
  4 packets transmitted, 4 packets received, 0.0% packet loss
  round-trip min/avg/max/stddev = 0.237/0.448/0.706/0.168 ms
  ```


## Access the WordPress Application

- Trust the self signed generated CA certificate file (`workspace/certs/k8s-local-ca.crt`) by
  following https://github.com/teracyhq-incubator/teracy-dev-certs#how-to-trust-the-self-signed-ca-certificate

- Open https://wordpress.k8s.local and you should see the default WordPress home page

- Open https://wordpress.k8s.local/wp-login.php to log in with the username and password defined
  in the `wordpress-override.yaml` file.

  + Note: if you can not login with the defined password (something wrong here, will be fixed later),
    you need to reset the password with the following commands:

    ```bash
    $ kubectl run mysql-client --image=bitnami/wordpress:4.9.8 -it --rm --restart=Never --namespace=wordpress bash
    If you don't see a command prompt, try pressing enter.
    root@mysql-client:/# mysql -h db-cluster-mysql-master -uroot -padmin
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MySQL connection id is 2040
    Server version: 5.7.23-24-log Percona Server (GPL), Release '24', Revision '57a9574'

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MySQL [(none)]> USE wordpress;
    Reading table information for completion of table and column names
    You can turn off this feature to get a quicker startup with -A

    Database changed
    MySQL [wordpress]> UPDATE wp_users SET user_pass = MD5('pass') WHERE ID=1;
    Query OK, 1 row affected (0.07 sec)
    Rows matched: 1  Changed: 1  Warnings: 0

    MySQL [wordpress]> exit
    Bye
    root@mysql-client:/# exit
    exit
    pod "mysql-client" deleted
    ```

- Enjoy!

## References

- https://github.com/presslabs/mysql-operator
- https://github.com/helm/charts/tree/master/stable/wordpress
