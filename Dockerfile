ARG BASE_REGISTRY
ARG BASE=ubuntu:24.04
FROM ${BASE_REGISTRY}${BASE}

ARG VARIANT=no-ml
ARG EXTRA_APT_PACKAGES=""
ARG EXTRA_PIP_PACKAGES=""

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES="all"
ENV TZ=UTC

RUN apt-get update -qqy && \
        apt-get upgrade -qqy && \
        apt-get install -qqy tzdata wget curl tmux less vim cmake git software-properties-common build-essential nfs-common jq python3-pip python3-venv $EXTRA_APT_PACKAGES > /dev/null && \
        apt-get clean -qqy

# node24 for notebook extensions
RUN curl -sL https://deb.nodesource.com/setup_24.x | bash - \
        && apt-get install -qqy nodejs > /dev/null \
        && apt-get clean -qqy

# CUDA (gpu variant only)
RUN if [ "$VARIANT" = "ml-gpu" ]; then \
        wget -q "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin" -O /etc/apt/preferences.d/cuda-repository-pin-600 \
        && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub \
        && add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/ /" \
        && apt-get install -y --no-install-recommends cuda-13-0 > /dev/null \
        && apt-get clean -qqy; \
    fi

USER ubuntu
WORKDIR /home/ubuntu

# Python virtualenv
RUN python3 -m venv /home/ubuntu/venv

# Torch: GPU or CPU build
RUN if [ "$VARIANT" = "ml-gpu" ]; then \
        /home/ubuntu/venv/bin/pip3 --no-cache-dir -q install torch==2.10.0 torchvision==0.25.0 --index-url https://download.pytorch.org/whl/cu130; \
    elif [ "$VARIANT" = "ml-cpu" ]; then \
        /home/ubuntu/venv/bin/pip3 --no-cache-dir -q install torch==2.10.0 torchvision==0.25.0 --index-url https://download.pytorch.org/whl/cpu; \
    fi

# python requirements
COPY --chown=ubuntu:ubuntu requirements.txt requirements-ml.txt ./
RUN /home/ubuntu/venv/bin/pip3 --no-cache-dir -q install -r requirements.txt $EXTRA_PIP_PACKAGES
RUN if [ "$VARIANT" = "ml-gpu" ] || [ "$VARIANT" = "ml-cpu" ]; then \
        /home/ubuntu/venv/bin/pip3 --no-cache-dir -q install -r requirements-ml.txt; \
    fi

# activate notebook extensions
RUN /home/ubuntu/venv/bin/jupyter labextension install jupyter-matplotlib > /dev/null


# Running the notebook server
COPY --chown=ubuntu:ubuntu run-notebook.sh run-notebook-server.sh ./
RUN chmod 755 ./*.sh && mkdir -p notebooks
EXPOSE 8888

CMD ["/home/ubuntu/run-notebook-server.sh"]
