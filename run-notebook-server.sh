#!/bin/sh

VENV=${VENV:-/home/ubuntu/venv/bin}
"${VENV}/jupyter-lab" --ip=0.0.0.0 --NotebookApp.port_retries=0 --notebook-dir=./notebooks $NOTEBOOK_EXTRA_ARGS
