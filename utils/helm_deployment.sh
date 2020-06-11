#!/bin/bash
# Sources:
# * Prometheus: https://github.com/helm/charts/tree/master/stable/prometheus
# * Grafana: https://github.com/helm/charts/tree/master/stable/grafana
# * Autoscaler: https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html

echo "This script assumes that it is ran from the root project directory. If there are any errors being thrown from this script regarding missing files, then make sure that it is ran from the correct directory."

# Airflow and LoadBalancer
helm install airflow helm/airflow-loadbalancer

# Prometheus
helm repo add common https://kubernetes-charts-incubator.storage.googleapis.com/
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
helm install -f helm/prometheus/values.yaml prometheus stable/prometheus

# Grafana
helm install -f helm/grafana/values.yaml grafana stable/grafana
echo 'Get the password for Grafana by running: "kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo"'

# Autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"

# Set up Autoscaler Deployment
# kubectl -n kube-system edit deployment.apps/cluster-autoscaler
#    spec:
#      containers:
#      - command:
#        - ./cluster-autoscaler
#        - --v=4
#        - --stderrthreshold=info
#        - --cloud-provider=aws
#        - --skip-nodes-with-local-storage=false
#        - --expander=least-waste
#        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/<YOUR CLUSTER NAME>
#        - --balance-similar-node-groups
#        - --skip-nodes-with-system-pods=false
# kubectl -n kube-system set image deployment.apps/cluster-autoscaler cluster-autoscaler=eu.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler:v1.16.n
