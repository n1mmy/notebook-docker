#!/bin/sh

jupyter-lab --ip=0.0.0.0 --allow-root --NotebookApp.port_retries=0 --notebook-dir=./notebooks $NOTEBOOK_EXTRA_ARGS
