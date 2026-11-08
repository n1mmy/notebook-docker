#!/bin/sh

VENV_DIR=${VENV_DIR:-/home/ubuntu/venv}
. "${VENV_DIR}/bin/activate"
jupyter-lab --ip=0.0.0.0 --ServerApp.port_retries=0 --notebook-dir=./notebooks $NOTEBOOK_EXTRA_ARGS
