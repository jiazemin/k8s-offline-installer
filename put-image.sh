#!/bin/bash
IMG_NAME="$1"
docker pull "${IMG_NAME}"
FN="$(echo "${IMG_NAME}" | tr '[/]' '_' | tr '[:]' '+').tgz"
mkdir -p "$2"
docker save ${IMG_NAME} | gzip -c > "$2/${FN}"

