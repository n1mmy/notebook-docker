ARG BASE_REGISTRY
ARG BASE=ubuntu:24.04
FROM ${BASE_REGISTRY}${BASE}

ARG VARIANT=no-ml

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES="all"
ENV TZ=UTC
WORKDIR /root

RUN apt-get update -qqy && \
        apt-get upgrade -qqy && \
        apt-get install -qqy tzdata wget curl tmux less vim cmake git software-properties-common build-essential nfs-common jq python3-pip python3-venv > /dev/null && \
        apt-get clean -qqy

# node20 for notebook extensions
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - \
        && apt-get install -qqy nodejs > /dev/null \
        && apt-get clean -qqy

# CUDA (gpu variant only)
RUN if [ "$VARIANT" = "ml-gpu" ]; then \
        wget -q "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin" -O /etc/apt/preferences.d/cuda-repository-pin-600 \
        && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub \
        && add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/ /" \
        && apt-get install -y --no-install-recommends nvidia-utils-560 cuda-12-6 > /dev/null \
        && apt-get clean -qqy; \
    fi

# Python virtualenv
RUN python3 -m venv /root/venv

# Torch: GPU or CPU build
RUN if [ "$VARIANT" = "ml-gpu" ]; then \
        /root/venv/bin/pip3 --no-cache-dir -q install torch==2.6.0 torchvision==0.21.0 --index-url https://download.pytorch.org/whl/cu126; \
    elif [ "$VARIANT" = "ml-cpu" ]; then \
        /root/venv/bin/pip3 --no-cache-dir -q install torch==2.6.0 torchvision==0.21.0 --index-url https://download.pytorch.org/whl/cpu; \
    fi

# rest of the python requirements
COPY requirements.txt .
RUN /root/venv/bin/pip3 --no-cache-dir -q install -r requirements.txt

# activate notebook extensions
RUN /root/venv/bin/jupyter labextension install jupyter-matplotlib > /dev/null


# Running the notebook server
COPY run-notebook.sh run-notebook-server.sh ./
RUN chmod 755 ./*.sh && mkdir -p notebooks
EXPOSE 8888

CMD ["/root/run-notebook-server.sh"]
