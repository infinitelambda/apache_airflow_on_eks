FROM <ECR BASE URL>

ARG AIRFLOW_HOME=/usr/local/airflow
ARG AIRFLOW_USER=airflow
ENV PATH "${AIRFLOW_HOME}:${PATH}"
ENV AIRFLOW_HOME=${AIRFLOW_HOME}
ENV AWS_DEFAULT_REGION=<AWS REGION>

RUN mkdir ${AIRFLOW_HOME}/tmp

# Install Python Dag Deps into virtualenv
COPY requirements.txt .
RUN . ${AIRFLOW_HOME}/venv/bin/activate && pip install -r requirements.txt
RUN rm -rf requirements.txt /root/.cache

# Deploy dags into airflow dags folder
COPY ./airflow-dags ${AIRFLOW_HOME}/dags
COPY ./ci ${AIRFLOW_HOME}/ci
COPY ./pipeline ${AIRFLOW_HOME}/pipeline

RUN chown -R ${AIRFLOW_USER}:${AIRFLOW_USER} ${AIRFLOW_HOME}
RUN chmod +x ${AIRFLOW_HOME}/ci/*.sh
WORKDIR ${AIRFLOW_HOME}
EXPOSE 8080
USER ${AIRFLOW_USER}
