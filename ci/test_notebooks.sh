#!/bin/bash
# Copyright (c) 2020-2023, NVIDIA CORPORATION.

set -euo pipefail

. /opt/conda/etc/profile.d/conda.sh

rapids-logger "Generate notebook testing dependencies"
rapids-dependency-file-generator \
  --output conda \
  --file_key test_notebooks \
  --matrix "cuda=${RAPIDS_CUDA_VERSION%.*};arch=$(arch);py=${RAPIDS_PY_VERSION}" | tee env.yaml

rapids-mamba-retry env create --force -f env.yaml -n test

# Temporarily allow unbound variables for conda activation.
set +u
conda activate test
set -u

rapids-print-env

rapids-logger "Downloading artifacts from previous jobs"
PYTHON_CHANNEL=$(rapids-download-conda-from-s3 python)

rapids-mamba-retry install \
  --channel "${PYTHON_CHANNEL}" \
  cuxfilter


NBTEST="$(realpath "$(dirname "$0")/utils/nbtest.sh")"
pushd notebooks

# Add notebooks that should be skipped here
# (space-separated list of filenames without paths)
SKIPNBS=""

EXITCODE=0
trap "EXITCODE=1" ERR
set +e
for nb in $(find . -name "*.ipynb"); do
    nbBasename=$(basename ${nb})
    # Skip all notebooks that use dask (in the code or even in their name)
    if ((echo ${nb} | grep -qi dask) || \
        (grep -q dask ${nb})); then
        echo "--------------------------------------------------------------------------------"
        echo "SKIPPING: ${nb} (suspected Dask usage, not currently automatable)"
        echo "--------------------------------------------------------------------------------"
    elif (echo " ${SKIPNBS} " | grep -q " ${nbBasename} "); then
        echo "--------------------------------------------------------------------------------"
        echo "SKIPPING: ${nb} (listed in skip list)"
        echo "--------------------------------------------------------------------------------"
    else
        nvidia-smi
        ${NBTEST} ${nbBasename}
    fi
done

rapids-logger "Test script exiting with value: $EXITCODE"
exit ${EXITCODE}
