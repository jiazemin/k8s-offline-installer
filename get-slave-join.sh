#!/bin/bash -x
####################################################################
# Kubernetes Installer for Master
# - Code by Jioh L. Jung
####################################################################

####################################################################
# Setup values
#- Log files
#TMP_LOG_FILE=$(mktemp /tmp/output.XXXXXXXXXX)

#- Root Check
if (( EUID != 0 )); then
    echo "You must be root to do this." 1>&2
    exit 1
fi

#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

#- Imports configure & functions
if [ -f "config" ]; then
  chmod +x config
  . ./config
fi
. ./default
. libs/functions

#- Remove Old Tokens
kubeadm token list | grep -v TOKEN | awk '{print $1}' | xargs -l1 -t -r kubeadm token delete || true

#- Generate New Tokens
TOKEN=`kubeadm token create --print-join-command 2> /dev/null`
#| tee ${TMP_LOG_FILE}

#- Generate Join Command
mkdir -p "${BASE_DIR}/nodes"
JOIN_SHELL_FILE_NAME="${BASE_DIR}/nodes/install-slave-node.${EXT_IP}.sh"
cd ${BASE_DIR}
cat << EOF > "${JOIN_SHELL_FILE_NAME}"
#!/bin/bash
cd "${BASE_DIR}"

${BASE_DIR}/install-common.sh
${BASE_DIR}/load-images.sh ./cni/${CNI_PLUGIN_TYPE}
${BASE_DIR}/load-images.sh ./images/shared/
${TOKEN}
EOF
chmod +x "${JOIN_SHELL_FILE_NAME}"

