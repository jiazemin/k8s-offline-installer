#!/bin/bash
####################################################################
# Docker dump file loader
# - Code by Jioh L. Jung
####################################################################

#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

echo "DIR>> $1"
#- Go to target Directory
if [[ ! -z "$1" ]]; then
  echo "> Change DIR to $1"
  cd "$1"
fi

#- Load from tgz file
for j in $(ls *.tgz) ; do
  echo "> ${j} loading.."
  gunzip -c ${j} | docker load
  echo "> ${j} Done.."
done

