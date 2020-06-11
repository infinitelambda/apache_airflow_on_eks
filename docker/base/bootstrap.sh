#!/bin/sh
airflow initdb
airflow create_user --username airflow --password $AFPW --role Admin --email airflow@airflow --firstname airflow --lastname airflow
exit 0
