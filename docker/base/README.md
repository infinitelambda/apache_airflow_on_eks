# Base folder

In this Project, we work with 2 Docker Images that we call Base and Dag. 
The base image is used to contain Airflow itself without the Airflow DAGs, and the Dag is used for only containing the Airflow DAGs. 
They are separated, because the Dag image gets built a lot more during a project, so we save building time this way but not having them in the same image. 
We also use virtualenv for further separation of the dependencies between the two.
  
This folder contains the everything that is needed to build the Base Image, along with the Dockerfile, it has:
- The config file for Airflow called ```airflow.cfg```
- A ```bootstrap.sh``` script which runs airflow initdb and creates an Airflow User. This executes once when the Helm Chart deployment for Airflow happens  
  (See helm/airflow-loadbalancer/templates/deployment.yaml/initContainers section)
- ```requirements.txt```, which contains Airflow's dependencies, e.g. the airflow-exporter, which is needed for using Prometheus with Airflow

The rebuilding of this image is only needed if something that is directly related to Airflow is changed, for example Airflow dependencies, Airflow version number.
