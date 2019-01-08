#!/bin/bash

#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

if [[ "$(docker images | grep rpmbuilder | wc -l)" -eq "0" ]]; then
  docker build -t rpmbuilder .
fi

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

#- Acquire Newest Version
HELM_VERSION=${HELM_VERSION:-"$(get_latest_release 'helm/helm' | tr -dc '\.0-9')"}
HELM_ARCH=${HELM_ARCH:-"linux-amd64"}
DATES_STR=`LC_ALL=c date "+%a %b %d %Y"`

#- Extract Version String Only
HELM_VERSION_TMP="$(echo "${HELM_VERSION}"| grep -o -E '[0-9\.\-]+')"


#- Generate RPM Spec File
cat helm.spec.template | \
 sed "s;_DATES_HERE_;${DATES_STR};g" | \
 sed "s;_HELM_VERSION_;${HELM_VERSION_TMP};g" | \
 cat > helm.spec

#- Builds
docker run -it --rm \
  -e HELM_VERSION="${HELM_VERSION_TMP}" \
  -e HELM_ARCH="${HELM_ARCH}" \
  --net=host \
  -v `pwd`:/root rpmbuilder rpmbuild -ba /root/helm.spec

mkdir -p ../rpm-packages
cp -f rpmbuild/RPMS/x86_64/* ../rpm-packages/
rm -rf rpmbuild helm.spec
