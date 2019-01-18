#!/bin/bash

SL_RELEASE="0.1"
DATES_STR=`LC_ALL=c date "+%a %b %d %Y"`

#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

WORK_DIR="./works"

if [[ "$(docker images | grep debbuilder | wc -l)" -eq "0" ]]; then
  docker build -t debbuilder .
fi


#- Generate Control File
mkdir -p ${WORK_DIR}/DEBIAN
cat  control.template | \
 sed "s;_SL_RELEASE_;${SL_RELEASE};g" | \
 sed "s;_DATES_HERE_;${DATES_STR};g" | \
 cat > ${WORK_DIR}/DEBIAN/control

#cp -f scripts/* ${WORK_DIR}/DEBIAN/

# Make Directories
mkdir -p ${WORK_DIR}/usr/local/hcdd/
cp sideloader ${WORK_DIR}/usr/local/hcdd/sideloader
mkdir -p ${WORK_DIR}/etc/systemd/system/
cp sideloader.service ${WORK_DIR}/etc/systemd/system/sideloader.service

#- Modify Files Permission
chmod 0755 ${WORK_DIR}/usr/local/hcdd/sideloader
chmod 0600 ${WORK_DIR}/etc/systemd/system/sideloader.service
chown root:root -R ${WORK_DIR}/*

#- Builds
docker run -it --rm \
  --net=host \
  -w /root \
  -v `pwd`:/root debbuilder bash -c "cd /root && dpkg -b /root/works"

mkdir -p ../deb-packages
mv works.deb ../deb-packages/sideloader-${SL_RELEASE}.deb
rm -rf ${WORK_DIR}
