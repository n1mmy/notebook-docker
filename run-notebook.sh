#!/bin/bash

NOTEBOOK="$1"

if [ -z "$NOTEBOOK" ] ; then
   echo "Usage: $0 <notebook.ipynb> [other args]"
   exit 1
fi

VENV={$VENV:-/root/venv/bin}
IPYTHON=${IPYTHON:-${VENV}/ipython3}

tmpfile=$(mktemp /tmp/notebook.exec.XXXXXX.py)
$VENV/jupyter nbconvert --log-level WARN --to python "$NOTEBOOK" --output "$tmpfile"

cd $(dirname $NOTEBOOK)
shift # drop notebook name from args
$IPYTHON "$tmpfile" -- $@
exitcode=$?

rm -f "$tmpfile"
exit $exitcode
