# Airflow on EKS

created by: Infinite Lambda. Visit our website: https://infinitelambda.com

This project is a template for easily deploying Apache Airflow on AWS EKS and using various functionalities of Airflow with DAGs that test the CPU and memory usage of differently sized instances, including two node groups and a Fargate profile.  

## Prerequisites:  
- Terraform  
- Helm  
- AWS CLI  
- Docker  
- Kubectl
- AWS Access keys in the credentials file under the aws directory

## Instructions for deployment:

### Terraform
> **WARNING**:
These templates use EKS with **Fargate**, which is only allowed in the bigger regions, so if you are deploying to a smaller region and do not need Fargate, you need to remove the following blocks from the following files:  
    - **terraform/eks.tf** **line 55 to 68**  
    - **terraform/eks.tf** **line 80 to 83**  
    - **terraform/eks.tf** **line 153 to 168**  
    - **helm/airflow-loadbalancer/templates/rbac.yaml** **line 23 to 45**  
    - **Skip the 6th step** in the Helm section **by not creating a fargate namespace**   

#### What resources does Terraform create in this project

- a VPC with 3 Public and 3 Private Subnets and a NAT Gateway  
- a Postgres RDS for storing the metadata that Airflow produces  
- an EKS Cluster with 2 Worker groups and 1 Fargate Profile  
- Two ECR Repositories for storing the Docker Images  
- an S3 Bucket to send the logs from the containers  
- an IAM User for Airflow to connect to the S3 Log Bucket  
- a Secrets Manager Secret for storing the Access Keys for the Airflow Logger IAM User  
- additional Security Groups, IAM Roles and Policies for giving accesses to all of the above Services to communicate with each other

#### Steps for deployment:

1. Change to the ```terraform``` folder
2. Supply values for all variables that can be found in **terraform/variables.tf**
3. Run ```terraform init``` to download the modules and the aws provider
4. Run ```terraform apply``` to begin the **deployment**. This **should take about 25-30 minutes**.  
5. When the deployment is finished, make sure that you review the **security groups** that Terraform created on the AWS Console, under EC2/VPC Security Groups, and **change accordingly if needed** (e.g. add more IPs), and **attach them to the EKS nodes, and to the RDS instance**.

The Terraform part of the project is finished here, the next step is to edit the following configuration files according to your AWS resources and their attributes.

### Helm and Auto Scaler

#### What the Helm folder contains in this project

- a Helm Chart for deploying Airflow and a Load Balancer for the EKS Nodes  
- a values file for parameterizing the [official Prometheus Helm Chart](https://github.com/helm/charts/tree/master/stable/prometheus), which can be used to scrape Airflow for metrics
- a values file for parameterizing the [official Grafana Helm Chart](https://github.com/helm/charts/tree/master/stable/grafana), which can be used to present metrics with dashboards

#### Auto Scaler

- For this project, we used the official AWS EKS cluster Auto Scaler, the guide for it can be found here:  
	[https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html](https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html)  
Along with the manual setup, we also have a script for deploying it as well, that can be partially (there's some manual steps at the end) used for setting this up.

#### Steps for deployment:

The Helm deployment of Airflow uses local files from this project, therefore the configuration of these files are needed. Futhermore, there are additional steps of configuration that are needed for all of these to work. Here are the steps for them:
  
1. Inside **docker/base/airflow.cfg** on **line 17**, add the name of the logs bucket Terraform created to the remote_base_log_folder property
2. In the **same file**, on **line 337**, add the dag ECR url to the worker\_container\_repository property  
3. Inside **docker/dag/Dockerfile**, add the base ECR url to the **first line** of the file, and add your **AWS Region** in **line 7**  
4. In **helm/airflow-loadbalancer/values.yaml**, add the dag ECR url, and a node label for telling Helm which instance(s) to deploy Airflow on  
5. Switch to your newly created cluster with the following commands from the command line:    
    ```aws eks --region <REGION> update-kubeconfig --name <EKS CLUSTER NAME> --profile <AWS CREDENTIALS PROFILE>```
    ```kubectl config set-context <EKS CLUSTER ARN>```  
6. Run ```kubectl create namespace fargate```
7. If there's two or more people that need to interact with the cluster, they also need to be given access inside the Auth YAML file (which can be opened with this command: ```kubectl edit -n kube-system configmap/aws-auth```) under the **mapUsers** section like this:
		
            mapUsers: |
              - userarn: <IAM User ARN>
              username: <Username> (the value for this doesn't come from anywhere, it can be anything)
              groups:  
                - system:masters  
  >*The mapUsers section has to align with the mapRoles section in the YAML file*
    
  Or a more automated process for authentication would be implementing this: [https://www.cloudjourney.io/articles/publiccloud/managing_eks_access-bs/?fbclid=IwAR1GeKce2URuH-1G_WO1ghGlP9CNS2H4V7Cbqr6aupCsok8iJoJZ2l7CBck](https://www.cloudjourney.io/articles/publiccloud/managing_eks_access-bs/?fbclid=IwAR1GeKce2URuH-1G_WO1ghGlP9CNS2H4V7Cbqr6aupCsok8iJoJZ2l7CBck)
  
8. Supply the password for the Airflow admin user by writing it in **helm/airflow-loadbalancer/files/secrets/airflow/AFPW**  
9. The connection url for the RDS also needs to be supplied in **helm/airflow-loadbalancer/files/secrets/airflow/AIRFLOW\_\_CORE\_\_SQL\_ALCHEMY\_CONN**  
   The url's format is the following:
   ```  
   postgresql+psycopg2://<RDS USER>:<RDS PASSWORD>@<RDS ENDPOINT>:5432/<RDS NAME>  
   ```
10. Build the base, then the dag Docker images (the script **utils/docker_build.sh** can be used for this process, but you will have to edit it beforehand for filling in the variables defined **at the top**)
11. Push the base and dag Docker images to their ECR repositories (the script **utils/docker_build.sh** can be used for this process, but you will have to edit it beforehand for filling in the variables defined at the top)  

   Finally, the Helm deployment will install **Airflow**, **Prometheus**, and **Grafana** in the cluster,     and a set up kubectl commands will install the **Autoscaler**.
    A script can be partially used for this (the deployment of the autoscaler needs manual editing), which     can be found inside **utils/helm_deployment.sh**.  

12. Install Airflow:  

    ```
    helm install airflow helm/airflow-loadbalancer
    ```

13. Prometheus:  

    ```
    helm repo add common https://kubernetes-charts-incubator.storage.googleapis.com/
    helm repo add stable https://kubernetes-charts.storage.googleapis.com
    helm repo update
    helm install -f helm/prometheus/values.yaml prometheus stable/prometheus
    ```

14. And Grafana:

    ```  
    helm install -f helm/grafana/values.yaml grafana stable/grafana
    ```

    Get the password for Grafana by running:  

    ```
    "kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo"
    ```

    When setting up a data source, add the value of **http://prometheus-server** to the **url** property under the **HTTP section**

15. Deploy the Autoscaler:  
Run these first:

    ```
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
    kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
    ```

    Then edit its deployment:

    ```
    kubectl -n kube-system edit deployment.apps/cluster-autoscaler
    ```

    Enter the following configuration:

    ```
        spec:
          containers:
          - command:
            - ./cluster-autoscaler
            - --v=4
            - --stderrthreshold=info
            - --cloud-provider=aws
            - --skip-nodes-with-local-storage=false
            - --expander=least-waste
            - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/<YOUR CLUSTER NAME>
            - --balance-similar-node-groups
            - --skip-nodes-with-system-pods=false
    ```

    And set the following image:

    ```
    kubectl -n kube-system set image deployment.apps/cluster-autoscaler cluster-autoscaler=eu.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler:v1.16.n
    ```

## Accessing Airflow and the monitoring services

After all these steps, the initial setup should be complete, the LoadBalancer's url, and the ports for Prometheus and Grafana can be checked with:  

```
kubectl get svc
```

And the EKS Node's IP addresses can be checked with:  

```
kubectl get node -o wide
```

### Setup of the Airflow S3 Logging

This covers how the Airflow DAG Logs can be exported into the S3 Bucket that Terraform created.

#### Steps:

1. Go to the **Airflow Console**
2. Click **Admin**, and then **Connections**
3. Add a **new record**
4. Set the **Conn Id** to ```s3-log-bucket```
5. Select **S3** **as** **Conn Type**
6. For the **Host**, enter a value with the following format: ```s3://<Your Log Bucket Name>/```
7. For **Login**, add the Airflow Logs IAM User's **Access Key Id**. **This can be found inside secrets manager**
8. For **Password**, add the **Secret Access Key** for the same IAM User. **This can also be found in secrets manager** as a secret

## Build process:

### Dag Image

Whenever there's any **change to the Airflow Dags**, the Dockerfile inside the dag folder can be **built into an image**, **and pushed into the ECR repository**.   

It **needs to have two different tags**, **latest** **and a tag that is different from the last one**. It is needed, because **Airflow uses it with the latest tag**, in places like the KubernetesPodOperator image argument, **and the other tag** is needed, **because kubectl cannot set a new image that has the same tag as the previous one**.  

For this process, we have script inside ```docker/dag/ci/``` called ```dag_rebuild.sh``` that **takes 1 argument**, **which is the tag** that needs to **different than the previous one**, which gets used inside the script, along with the latest tag. The script assumes that it is ran from the root project folder, and the value for the Dag ECR Url and for the AWS Region also need to be filled inside the script. Inside a CI process, the unique tag can come from the build ID, or from the commit ID, as those are going do be different then the IDs before it.

### Base Image

Whenever there's **any change** **related to** a **direct funcionality of Airflow**, e.g. the Airflow version number, a dependency of Airflow, **then the base** **and after that the dag image needs to be rebuilt**. A **script can also be used for this**, and it is inside the ```utils``` folder called ```docker_build.sh```




