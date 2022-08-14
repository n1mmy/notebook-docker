# Introduction

This repo contains build scripts and instructions for a Jupyter notebook server with a recent CUDA-enabled pytorch using docker. Additionally there are build configurations and example files for building and deploying the image in the cloud.

I use this personally as a base image for machine learning experiments in the cloud. It may not be maintained or updated on a timely basis, and may change without warning.

It has:
- Ubuntu 22.04 base image
- CUDA 11.7 libraries
- pytorch 1.12.1 with torchvision
- JupyterLab notebook server
- Node.js 16 for notebook extensions
- `aws` command line tools and python packages.


For quick experiments you can use a pre-built image directly from `ghcr.io/n1mmy/notebook`, either as a complete solution or as a base layer to build on top of. For production use or for customization, you may wish to fork this repository and build the image yourself.


# Table of Contents

* [Local usage](#local-usage)
  * [Quickstart](#quickstart)
  * [Building the image](#building-the-image)
  * [Additional customization](#additional-customization)
    * [NOTEBOOK_EXTRA_ARGS](#notebook_extra_args)
    * [run-notebook.sh](#rootrun-notebooksh)
    * [docker --shm-size](#docker---shm-size)
* [Building in the cloud](#building-in-the-cloud)
  * [Google Cloud Build](#google-cloud-build)
  * [AWS CodeBuild](#aws-codebuild)
* [Running in the cloud](#running-in-the-cloud)
  * [Kubernetes](#kubernetes)
  * [Bare AWS instances with EFS](#bare-aws-instances-with-efs)
* [TODO](#todo)


# Local usage

## Quickstart

If you have a machine with an NVIDIA GPU-enabled version of docker installed [[guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)], you can get started quickly using a pre-built image:

```
docker run -it --gpus all -p 8888:8888 -v ~/my_notebook_dir:/root/notebooks ghcr.io/n1mmy/notebook
```

This will print a URL to the console like `http://127.0.0.1:8888/lab?token=f981019486f356267af792986cea36c3c4bc9d106a30952b`. Load this in your browser and you should have a functional Jupyter installation ready for your experiments.

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

To allow customization the contents of the `NOTEBOOK_EXTRA_ARGS` environment variable are passed to the JupyterLab server process as command line arguments. This can be used, for example, to set a password on the server instead of having to get a new unique URL each time. The following sets up a notebook server with the password `hi there` (compute the hash for your own password with `echo -n 'your password' | shasum`):

```
docker run -it --gpus all -p 8888:8888 \
  -v ~/my_notebook_dir:/root/notebooks \
  -e 'NOTEBOOK_EXTRA_ARGS=--NotebookApp.password=sha1:56170f5429b35dea081bb659b884b475ca9329a9' \
  ghcr.io/n1mmy/notebook
```

Or, if you prefer to disable the password and only allow connections from `localhost`:

```
docker run -it --gpus all -p 127.0.0.1:8888:8888 \
  -v ~/my_notebook_dir:/root/notebooks \
  -e "NOTEBOOK_EXTRA_ARGS=--NotebookApp.password='' --NotebookApp.token=''" \
  ghcr.io/n1mmy/notebook
```

*NOTE*: turning off password/token authentication can be dangerous. Be sure you understand the security implications and limit access to the notebook server port.

### `/root/run-notebook.sh`

There is an additional shell script packaged in the image designed to allow for running Jupyter notebooks from the command line and in automated jobs.

The script `/root/run-notebook.sh` takes a the first argument as a path to a notebook (`.ipynb`) file. It converts this notebook file to a plain python script then runs that script, passing it any additional command line arguments.

Here is an example docker command that to run a notebook file and print the output to stdout.


An example Kubernetes manifest for a Job that runs a notebook is available in [example-k8s-job.yaml](example-k8s-job.yaml)


### `docker --shm-size`

This isn't so much a feature of the image as warning to users. pytorch makes heavy use of shared memory and docker by default provides a fairly small amount to containers.

If you encounter out of memory errors while seeming to have lots of memory available, use the `--shm-size` argument to your docker invokation to allow the container to use more shared memory. For example, `--shm-size 32G` if your machine has 64GB of RAM.

The file `example-k8s-deployment.yaml` in this repository demonstrates how to give access to shared memory in a Kubernetes deployment using a volume mounted to `/dev/shm`.

# Building in the cloud

## Google Cloud Build

There is a `cloudbuild.yaml` file provided that builds the image and pushes it to Google Container Registry.

See https://cloud.google.com/build/docs/quickstart-automate for a tutorial on setting up a Cloud Build Trigger. You can use this repository instead of the example repo.

## AWS CodeBuild

There is a `buildspec.yml` file provided that builds the image and pushes it to Amazon Elastic Container Registry.

See https://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html for a tutorial on setting up a Codebuild to build the image. You can use this repository directly from Github or fork/copy it to a different Codebuild compatible source.


# Running in the cloud

## Kubernetes

There is an example manifest for a deployment of the notebook server in [example-k8s-deployment.yaml](example-k8s-deployment.yaml).

There is also an example manifest for creating a Job that runs a notebook file in [example-k8s-job.yaml](example-k8s-job.yaml).


## Bare AWS instances with EFS

Here is a process to get a notebook server (or multiple servers) running in AWS with persistent shared storage on Elastic File System. I find this a convienient setup as it allows for using starting and stopping instances as needed, as well as multiple instances at once.

The process should be basically the same on other cloud providers as well.

1. Create an EFS instance
 - Visit https://console.aws.amazon.com/efs/home and click "Create file system"

2. Start an instance running Ubuntu 20.04
 - Visit https://console.aws.amazon.com/ec2/v2/home and click "Launch instance"
 - Type "Ubuntu" into the AMI search box and select "Ubuntu Server 20.04 LTS (HVM), SSD Volume Type" (AMI ID will vary by region)
 - Pick an instance type with a GPU (The new `g5` instances are relatively cheap and quite nice). Click 'Configure Instance Details' not 'Review and Launch' for more options.
 - On the instance details page
  - Add the EFS instance by clicking "Add file system"
  - If you want to have the instance able to perform AWS API calls, remember to select a role for the machine on this page.
  - You may also want to request a Spot instance to pay less money.
  - Click "Add Storage" to move to the next page.
 - On the Add Storage page change the size of the root disk. The default 8GB is too small for this image. At least 50GB is recommended.
 - Optionally, continue through "Add tags" to "Configure security groups". The default of only allowing SSH is good, and you can use SSH port forwarding to access the notebook server. However, if you want to expose the notebook server to the internet (not recommended) you can add access to port 8888 here.
 - Launch the instance.

3. Once the instance is running, ssh in with port forwarding
 - `ssh -L 8888:localhost:8888 ubuntu@IP_OF_INSTANCE`

4. Setup nvidia driver and docker
```
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list


sudo wget "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin" -O /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"


sudo apt install -y --no-install-recommends nvidia-driver-510 nvidia-settings nvidia-docker2

sudo modprobe nvidia
```

5. Confirm GPU detected.
 - Run `nvidia-smi` and see a GPU in the output.

6. Add local storage (skip if your instance type doesn't have this)
```
sudo mkfs.ext4 /dev/nvme1n1
sudo mkdir /mnt/local
sudo mount /dev/nvme1n1 /mnt/local
```

7. Run notebook server
```
# password: 'hi there'
# remove /mnt/local line if no instance local storage
# adjust shm-size argument based on instance RAM size
sudo docker run -d --gpus all -p 8888:8888 \
  --shm-size 64G \
  -v /mnt/efs/fs1/my_notebook_dir:/root/notebooks \
  -v /mnt/local:/root/notebooks/local \
  -e 'NOTEBOOK_EXTRA_ARGS=--NotebookApp.password=sha1:56170f5429b35dea081bb659b884b475ca9329a9' \
  ghcr.io/n1mmy/notebook
```


# TODO

- different image flavors (eg w/ and w/o aws)
- opencv gpu build
- decord
