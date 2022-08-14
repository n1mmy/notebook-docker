ARG BASE_REGISTRY
ARG BASE=ubuntu:22.04
FROM ${BASE_REGISTRY}${BASE}

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES="all"
ENV TZ=UTC
WORKDIR /root

RUN apt-get update -qqy && \
        apt-get upgrade -qqy && \
        apt-get install -qqy tzdata wget curl tmux less vim cmake git software-properties-common build-essential nfs-common jq python3-pip > /dev/null && \
        apt-get clean -qqy

RUN wget -q "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin" -O /etc/apt/preferences.d/cuda-repository-pin-600 \
        && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub \
        && add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /" && \
        apt-get install -qqy --no-install-recommends nvidia-utils-515  libgl-dev cuda-11-7 > /dev/null && \
        apt-get clean -qqy


# GPU version of torch
RUN pip3 --no-cache-dir -q install --upgrade pip \
        && pip3 --no-cache-dir -q install torch==1.12.1+cu116 torchvision==0.13.1+cu116 -f https://download.pytorch.org/whl/torch_stable.html

# rest of the python requirements
COPY requirements.txt .
RUN pip3 --no-cache-dir -q install -r requirements.txt

# node16 for notebook extensions
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
        && apt-get install -qqy nodejs > /dev/null \
        && apt-get clean -qqy

# activate notebook extentions
RUN jupyter labextension install jupyter-matplotlib > /dev/null


# Running the notebook server
COPY run-notebook.sh run-notebook-server.sh ./
RUN chmod 755 ./*.sh && mkdir -p notebooks
EXPOSE 8888

CMD ["/root/run-notebook-server.sh"]
