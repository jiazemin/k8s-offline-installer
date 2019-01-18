#!/bin/bash
#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

if [[ "$(docker images | grep rpmbuilder | wc -l)" -eq "0" ]]; then
  docker build -t rpmbuilder .
fi

DATES_STR=`LC_ALL=c date "+%a %b %d %Y"`

SL_RELEASE="0.1"

#- Generate RPM Spec File
cat sideloader.spec.template | \
   sed "s;_SL_RELEASE_;${SL_RELEASE};g" | \
   sed "s;_DATES_HERE_;${DATES_STR};g" | \
   cat > sideloader.spec

#- Builds
docker run -it --rm \
  --net=host \
  -v `pwd`:/root rpmbuilder rpmbuild -ba /root/sideloader.spec

mkdir -p ../rpm-packages/
cp -f rpmbuild/RPMS/x86_64/* ../rpm-packages/
rm -rf rpmbuild sideloader.spec
