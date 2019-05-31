# Monitoring

This is the guide for setting up monitoring and alerting for k8s clusters with Prometheus.


## Prerequisites

- a k8s cluster available by following https://github.com/teracyhq-incubator/teracy-dev-entry-k8s#how-to-use.

- [Rook storage service](rook-storage-service.md) to set up the rook-ceph-block storage class.

- Make sure to set the vm's memory to be at least 4GB: https://github.com/teracyhq-incubator/teracy-dev-k8s#configuration-override


## Installation

- Execute the following commands:

```bash
$ cd docs/monitoring
$ helm upgrade --install prometheus-operator stable/prometheus-operator -f override.yaml --namespace=monitoring
```

  You can customize as much as possible on the `override.yaml` file.

- You should see the following output:

```bash
$ kubectl -n monitoring get pods
NAME                                                      READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-operator-alertmanager-0           2/2     Running   2          7h49m
prometheus-operator-grafana-5577649ff9-xb7c7              2/2     Running   2          8h
prometheus-operator-kube-state-metrics-79f476bff6-d5tn6   1/1     Running   1          8h
prometheus-operator-operator-58566bc59-q9924              1/1     Running   1          8h
prometheus-operator-prometheus-node-exporter-qzwkx        1/1     Running   1          8h
prometheus-prometheus-operator-prometheus-0               3/3     Running   4          7h49m
```


```bash
$ kubectl -n monitoring get pvc
NAME                                                                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
alertmanager-prometheus-operator-alertmanager-db-alertmanager-prometheus-operator-alertmanager-0   Bound    pvc-fb5e078e-8365-11e9-b18b-080027c2be11   5Gi        RWO            rook-ceph-block   7h49m
prometheus-prometheus-operator-prometheus-db-prometheus-prometheus-operator-prometheus-0           Bound    pvc-fd5cb63f-8365-11e9-b18b-080027c2be11   5Gi        RWO            rook-ceph-block   7h49m
```

## Prometheus Access

- Forward the Prometheus server to your machine:

```bash
$ kubectl port-forward -n monitoring prometheus-prometheus-operator-prometheus-0 9090
```

- Open http://localhost:9090


## Grafana Access

- Forward the Grafana server to your machine:

```bash
$ kubectl port-forward $(kubectl get  pods --selector=app=grafana -n  monitoring --output=jsonpath="{.items..metadata.name}") -n monitoring 3000
```

- Open http://localhost:3000 and login with the default `admin` as the username and `prom-operator`
  as the password.


## Alertmanager Access

- Forward the Alertmanager server to your machine:

```bash
$ kubectl port-forward -n monitoring alertmanager-prometheus-operator-alertmanager-0 9093
```

- Open http://localhost:9093

## Learn more

- To develop Prometheus rules and Grafana dashboards, follow: https://github.com/helm/charts/tree/master/stable/prometheus-operator#developing-prometheus-rules-and-grafana-dashboards


## References

- https://itnext.io/kubernetes-monitoring-with-prometheus-in-15-minutes-8e54d1de2e13
- https://www.weave.works/technologies/monitoring-kubernetes-with-prometheus/
- https://sysdig.com/blog/kubernetes-monitoring-prometheus/
- https://github.com/helm/charts/tree/master/stable/prometheus-operator
