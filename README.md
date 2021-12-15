# WORK IN PROGRESS

This is under development and not ready for public use.

# Introduction

This repo contains build scripts and instructions for a Jupyter notebook server with a recent CUDA-enabled pytorch using docker.

Additionally there are build configurations and example files for building and deploying the image in the cloud.

It has:
- Ubuntu 20.04 base image
- CUDA 11.5 libraries
- pytorch 1.10 with torchvision
- JupyterLab notebook server
- Node 16 for notebook extensions
- `aws` command line tools and python packages.


You can use a pre-built image directly from `ghcr.io` as a complete solution or as a base layer to build on top of. Or you can fork this repo and modify the build scripts for your own use case.


# Table of Contents


# Local usage

## Quickstart

If you have a machine with an NVIDIA GPU-enabled version of docker installed [1], you can get started quickly using a pre-built image:

```
docker run -it --gpus all -p 8888:8888 -v ~/my_notebook_dir:/root/notebooks ghcr.io/n1mmy/notebook
```

This will print a URL to the console like XXX. Load this in your browser and you should have a functional Jupyter installation ready for your experiments.

## Building the image

If you want to make changes -- for example to include more python packages in `requirements.txt` -- you can check out this repository, make changes in the your working copy, and build the image locally:

```
git clone https://github.com/n1mmy/notebook-docker
cd notebook-docker
docker build -t notebook .
```

And then run your local copy with:

```
docker run -it --gpus all -p 8888:8888 -v ~/my_notebook_dir:/root/notebooks notebook
```

## Additional customization

### `NOTEBOOK_EXTRA_ARGS`

To allow customization, the contents of the `NOTEBOOK_EXTRA_ARGS` environment variable are passed to the JupyterLab server process as command line arguments. This can be used, for example, to set a password on the server instead of having to get a new unique URL each time. The following sets up a notebook server with the password `hi there` (compute the hash for your own password with `echo -n 'your password' | shasum`):

```
docker run -it --gpus all -p 8888:8888 \
  -v ~/my_notebook_dir:/root/notebooks \
  -e 'NOTEBOOK_EXTRA_ARGS=--NotebookApp.password=sha1:56170f5429b35dea081bb659b884b475ca9329a9'
  ghcr.io/n1mmy/notebook
```

Or, if you prefer to disable the password and only allow connections from `localhost` 

### `/root/run-notebook.sh`



### `docker --shm-size`

This isn't so much a feature of the image as warning to users. pytorch makes heavy use of shared memory and docker by default provides a fairly small amount to containers.

If you encounter out of memory errors while seeming to have lots of memory available, use the `--shm-size` argument to your docker invokation to allow the container to use more shared memory. For example, `--shm-size 32G` if your machine has 64GB of RAM.

The file `example-k8s-deployment.yaml` in this repository demonstrates how to give access to shared memory in a Kubernetes deployment using a volume mounted to `/dev/shm`.

# Cloud Building

## Google Cloud Build

There is a `cloudbuild.yaml` file provided that builds the image and pushes it to Google Container Registry.

See https://cloud.google.com/build/docs/quickstart-automate for a tutorial on setting up a Cloud Build Trigger. You can use this repository instead of the example repo.

Quick outline of steps using the GCP web console:
- Fork this repo to your own GitHub account
- 'Connect Repository' on the Cloud Build page in the web console.
 - Go through the GitHub OAuth flow for cloud builder if you haven't already.
 - XXX
- 'Create Trigger' on the Cloud Build page in the web console.
XXX

## AWS CodeBuild

# Running in the cloud

## Kubernetes

There is an example manifest for a deployment of the notebook server in `example-k8s-deployment.yaml`.


## Ubuntu 20.04 Cloud Images


