#!/bin/bash
####################################################################
# Generate Cert. for Master
# - Code by Jioh L. Jung
####################################################################

#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

#- Imports configure & functions
if [ -f "config" ]; then
  chmod +x config
  . ../config
fi
. ../default
. ../libs/functions

####################################################################
CERT_DOMAINS=${CERT_DOMAINS:-"servers"}
CERT_RSA_KEY_SIZE=${RSA_KEY_SIZE:-"4096"}
CERT_MAX_DAYS=${CERT_MAX_DAYS:-"7300"}


# RSA Key generate
if [ ! -f "${HOME}/.ssh/id_rsa" ]; then
  mkdir -p ${HOME}/.ssh
  ssh-keygen -b ${RSA_KEY_SIZE} -t rsa -f ${HOME}/.ssh/id_rsa -q -N ""
fi

# SSH-Keys Generation (for HTTPS)
CERT_DOMAINS="servers"
if [ ! -f "${CERT_DOMAINS}.pem" ]; then
  #- Generate a unique private key (KEY)
  openssl genrsa -out ./config/${CERT_DOMAINS}.key ${RSA_KEY_SIZE}
  #- Generating a Certificate Signing Request (CSR)
  openssl req -batch -new -key ./config/${CERT_DOMAINS}.key -out ./config/${CERT_DOMAINS}.csr
  #- Creating a Self-Signed Certificate (CRT)
  openssl x509 -req -days ${CERT_MAX_DAYS} -in ./config/${CERT_DOMAINS}.csr -signkey ./config/${CERT_DOMAINS}.key -out ./config/${CERT_DOMAINS}.crt
  #- Append KEY and CRT to mydomain.pem
  rm -f ./config/${CERT_DOMAINS}.pem
  cat ./config/${CERT_DOMAINS}.key ./config/${CERT_DOMAINS}.crt >> ./config/${CERT_DOMAINS}.pem
fi
