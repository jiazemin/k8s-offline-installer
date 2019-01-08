#!/bin/bash
####################################################################
# Kubernetes Installer for Master
# - Code by Jioh L. Jung
####################################################################
#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

cd ./helm
mkdir -p mirror
./chart_mirror.py

curl -LO https://s3.amazonaws.com/chartmuseum/release/latest/bin/linux/amd64/chartmuseum
chmod +x chartmuseum

tar -czvf helm-chart.tgz mirror  chartmuseum
