ARG BASE=ubuntu:20.04
FROM ${BASE}

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES="all"
ENV TZ=UTC
WORKDIR /root

RUN apt-get update -q && \
        apt-get upgrade -qy && \
        apt-get install -qy tzdata wget curl tmux less vim cmake git software-properties-common build-essential nfs-common jq python3-pip  && \
        apt-get clean -qy

RUN wget "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin" -O /etc/apt/preferences.d/cuda-repository-pin-600 \
        && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub \
        && add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /" && \
        apt-get install -qy --no-install-recommends nvidia-utils-495 libgl-dev cuda-11-5 libcudnn8 libcudnn8-dev && \
        apt-get clean -qy


# GPU version of torch
RUN pip3 install --upgrade pip \
        && pip3 install torch==1.10.0+cu113 torchvision==0.11.1+cu113 -f https://download.pytorch.org/whl/torch_stable.html \
        && rm -rf ~/.cache/pip


COPY requirements.txt .
RUN pip3 install -r requirements.txt && \
        rm -rf ~/.cache/pip


# Running the notebook server
COPY run-notebook-server.sh .
RUN chmod 755 ./run-notebook-server.sh

CMD ["/root/run-notebook-server.sh"]
