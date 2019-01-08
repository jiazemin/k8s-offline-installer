#!/bin/bash
####################################################################
# Docker Images dumpers
# - Code by Jioh L. Jung
####################################################################

#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

#- Go to target Directory
if [[ ! -z "$1" ]]; then
  echo "> Change DIR to $1"
  mkdir -p "$1"
  cd "$1"
fi

for j in $(docker images | tail -n +2 | awk '{printf "%s:%s\n", $1, $2}')
do
  FN="$(echo "$j" | tr '[/]' '_' | tr '[:]' '+').tgz"
  if [ -f "${FN}" ]; then
    echo ">> File Existed: ${FN}"
    if [ "${FN: -10}" == "latest.tgz" ]; then
      echo ">> Overwrite (latest tag)"
      echo "> ${j} Saving -> ${FN}.."
      docker save ${j} | gzip -c > ${FN}
      echo "> ${j} Done.."
    fi
  else
    echo "> ${j} Saving -> ${FN}.."
    docker save ${j} | gzip -c > ${FN}
    echo "> ${j} Done.."
  fi
done

