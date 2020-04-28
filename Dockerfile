
# Dockerfile may have following Arguments: tag, pyVer, branch
# tag - tag for the Base image, (e.g. 1.10.0-py3 for tensorflow)
# pyVer - python versions as 'python' or 'python3'
# branch - user repository branch to clone (default: master, other option: test)

ARG tag=1.12.0-gpu-py36

# Base image, e.g. tensorflow/tensorflow:1.10.0-py3
FROM deephdc/tensorflow:${tag}

LABEL maintainer='HMGU'
LABEL version='0.1.0'
# Retinopathy classification using Tensorflow


# it is python3 code
ARG pyVer=python3

# What user branch to clone (!)
ARG branch=master

# If to install JupyterLab
ARG jlab=true

# Install ubuntu updates and python related stuff
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
         git \
         curl \
         wget \
         libsm6 \
         libxext6 \
         libxrender1 \
         gcc python3-dev \
         $pyVer-setuptools \
         $pyVer-pip \
         $pyVer-wheel && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/* && \
    if [ "$pyVer" = "python3" ] ; then \
       if [ ! -e /usr/bin/pip ]; then \
          ln -s /usr/bin/pip3 /usr/bin/pip; \
       fi; \
       if [ ! -e /usr/bin/python ]; then \
          ln -s /usr/bin/python3 /usr/bin/python; \
       fi; \
    fi && \
    python --version && \
    pip install --upgrade pip && \
    pip --version

# install rclone
RUN wget https://downloads.rclone.org/rclone-current-linux-amd64.deb && \
    dpkg -i rclone-current-linux-amd64.deb && \
    apt install -f && \
    mkdir /srv/.rclone/ && touch /srv/.rclone/rclone.conf && \
    rm rclone-current-linux-amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*

# Set LANG environment
ENV LANG C.UTF-8

# Set the working directory
WORKDIR /srv

# Install DEEPaaS from PyPi
# Install FLAAT (FLAsk support for handling Access Tokens)
RUN pip install --no-cache-dir \
        'deepaas>=1.0.0' \
        flaat && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*

# Disable FLAAT authentication by default
ENV DISABLE_AUTHENTICATION_AND_ASSUME_AUTHENTICATED_USER yes

# Install DEEP debug_log scripts:
RUN git clone https://github.com/deephdc/deep-debug_log /srv/.debug_log

# Install JupyterLab
ENV JUPYTER_CONFIG_DIR /srv/.jupyter/
# Necessary for the Jupyter Lab terminal
ENV SHELL /bin/bash
RUN if [ "$jlab" = true ]; then \
       pip install --no-cache-dir jupyterlab ; \
       git clone https://github.com/deephdc/deep-jupyter /srv/.jupyter ; \
    else echo "[INFO] Skip JupyterLab installation!"; fi

# Expand memory usage limit
# RUN ulimit -s 32768

# Install user app:

# RUN git clone https://github.com/itokeiic/retinopathy_test && \
# RUN git clone -b training_branch https://github.com/itokeiic/retinopathy_test && \

# clone only the last commit from github
# RUN git clone --depth 1 -b $branch https://github.com/vykozlov/retinopathy_test && \

RUN git clone --depth 1 -b $branch https://github.com/deephdc/retinopathy_test && \
    cd  retinopathy_test && \
    pip install --no-cache-dir -e . && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/* && \
    cd ..

# Open DEEPaaS port
EXPOSE 5000


# Open Monitoring  and Jupyter ports
EXPOSE 6006 8888

# Account for OpenWisk functionality (deepaas >=0.5.0)
CMD ["deepaas-run", "--openwhisk-detect", "--listen-ip", "0.0.0.0", "--listen-port", "5000"]

