from datetime import datetime, timedelta
import json
import sys
import os

# AIRFLOW LIBRARIES
from airflow import DAG
from airflow.models import Variable
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator
from airflow.operators.dummy_operator import DummyOperator

# UTILS
sys.path.append(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))

# Airflow ENV variables
# DAG_SCHEDULE uses cron schedule expressions to set time for triggering dag
# They are stored in Airflow's UI under Admin/Variables where you can edit/add/delete said variables
# To make sure you've set the correct variable you can double check here https://crontab.guru/
# Currently no variables
## ========================================= 👇 TO MODIFY WHEN COPY 👇 =======================##
DAG_SCHEDULE                    = None
DAG_NAME                        = 'launch_memory_user_medium_dag'
DESCRIPTION                     = "Launch script with medium memory usage"
## ========================================= 👆 TO MODIFY WHEN COPY 👆 =======================##

START_DATE                      = datetime(year=2020, month=2, day=24, hour=1, minute=1)
CATCHUP                         = False
AIRFLOW_HOME                    = "/usr/local/airflow"

# DEFINE THE DAG AND ITS ARGS
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": START_DATE,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 3,
    "retry_delay": timedelta(seconds=30)
}

dag = DAG(
    DAG_NAME,
    schedule_interval=DAG_SCHEDULE,
    start_date=START_DATE,
    catchup=CATCHUP,
    default_args=default_args,
    description=DESCRIPTION
)

start_task = DummyOperator(task_id='start_task', dag=dag)



# tasks
task = KubernetesPodOperator(namespace='default',
                                image="<ECR DAG URL>",
                                image_pull_policy="Always",
                                is_delete_operator_pod=True,
                                name=DAG_NAME,
                                in_cluster=True,
                                task_id=DAG_NAME,
                                cmds=["/bin/bash", "-c"],
                                arguments=["source /usr/local/airflow/venv/bin/activate && /usr/local/airflow/ci/launch_memory_user_medium.sh"],
                                startup_timeout_seconds=600,
                                resources = {'request_cpu': '1.00', 'request_memory': '4Gi'},
                                get_logs=True,
                                default_args=default_args
                                )

start_task.set_downstream(task)

start_task
