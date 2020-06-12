FROM python:3.7-slim-buster

# Airflow Config
ARG AIRFLOW_VERSION=1.10.10
ARG AIRFLOW_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS="kubernetes,s3,password,crypto"
ARG AIRFLOW_USER=airflow
ENV AIRFLOW_GPL_UNIDECODE yes

# Update and Install necessary libs then cleanup
RUN apt-get update -yqq \
  && apt-get upgrade -yqq \
  && apt-get dist-upgrade -yqq \
  && apt-get install -yqq --no-install-recommends \
    build-essential \
    libssl-dev \
    libffi-dev \
    libpq-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# upgrade pip
RUN pip3 install --upgrade pip

# Airflow preinstall Deps
COPY requirements.txt .
RUN pip3 install -r requirements.txt
RUN rm -f requirements.txt

# Airflow Installation
RUN pip3 install apache-airflow[${AIRFLOW_DEPS}]==${AIRFLOW_VERSION}
COPY airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

# installing virtualenv
RUN python3 -m virtualenv ${AIRFLOW_HOME}/venv
RUN rm -rf requirements.txt /root/.cache
# bootstrap
COPY bootstrap.sh /usr/local/bin/bootstrap.sh
RUN chmod +x  /usr/local/bin/bootstrap.sh

# Env Config
RUN useradd -d ${AIRFLOW_HOME} -s /bin/bash ${AIRFLOW_USER}
EXPOSE 8080
ENV PATH "${AIRFLOW_HOME}:${PATH}"
ENV AIRFLOW_HOME=${AIRFLOW_HOME}
WORKDIR ${AIRFLOW_HOME}
