# Base image, e.g. tensorflow/tensorflow:1.7.0
#FROM tensorflow/tensorflow:1.10.1-gpu
FROM tensorflow/tensorflow:1.10.1

LABEL maintainer='HMGU'
LABEL version='0.1'
# Retinopathy classification using Tensorflow


# Install ubuntu updates and python related stuff
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
         git \
         curl \
         wget \
         libsm6 \
         libxext6 \
         libxrender1 \
         python-setuptools \
         python-pip \
         python-wheel && \ 
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*
# install rclone
RUN wget https://downloads.rclone.org/rclone-current-linux-amd64.deb && \
    dpkg -i rclone-current-linux-amd64.deb && \
    apt install -f && \
    rm rclone-current-linux-amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/*

# Set LANG environment
ENV LANG C.UTF-8

# Set the working directory
WORKDIR /srv

# Install user app:
#RUN git clone -b training_branch https://github.com/itokeiic/retinopathy_test && \

RUN git clone https://github.com/itokeiic/retinopathy_test && \
    cd  retinopathy_test && \
    pip install --no-cache-dir -e . && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/* && \
    cd ..

# Install DEEPaaS:
RUN git clone https://github.com/indigo-dc/deepaas && \
    cd deepaas && \
    pip install --no-cache-dir -U . && \
    rm -rf /root/.cache/pip/* && \
    rm -rf /tmp/* && \
    cd ..

#####
# Your code may download necessary data automatically or 
# you force the download during docker build. Example below is for latter case:
#ENV Resnet50Data DogResnet50Data.npz
#ENV S3STORAGE https://s3-us-west-1.amazonaws.com/udacity-aind/dog-project/
#RUN curl -o ./dogs_breed_det/models/bottleneck_features/${Resnet50Data} \
#    ${S3STORAGE}${Resnet50Data}


# Open DEEPaaS port
EXPOSE 5000

CMD ["deepaas-run","--listen-ip=0.0.0.0"]
