#!/bin/bash

set -e

REVISION="0.1"

while getopts v: option
do
  case $option in
    v) VERSION=$OPTARG;;
  esac
done

if [ -z $VERSION ]; then
  echo "Usage: $0 -v <server-version>"
  exit
fi

# prepare working dir
case "$0" in
  /* ) SCRIPT="$0" ;;
  ./* ) SCRIPT="$PWD/${0#./}" ;;
  */* ) SCRIPT="$PWD/$0" ;;
  * ) echo "Unkown Error"; exit 1 ;;
esac

SCRIPT_DIR=${SCRIPT%/*}

SRC_DIR=$SCRIPT_DIR/../src

if [ ! -d $SRC_DIR ]; then
  mkdir -p $SRC_DIR
fi
SRC_DIR=$(realpath $SCRIPT_DIR/../src)
cd $SRC_DIR

# export the requested version from svn
BASE_URL="http://selenium.googlecode.com/files/"
FILE_NAME=selenium-server-standalone-${VERSION}.jar

if [ ! -d "$VERSION" ]; then
  mkdir $VERSION
  cd $VERSION
  wget $BASE_URL$FILE_NAME
fi

# prepare packages
PACKAGE_DIR=$SCRIPT_DIR/../packages
if [ -d $PACKAGE_DIR ]; then
  sudo rm -Rf $PACKAGE_DIR
fi 
mkdir $PACKAGE_DIR
PACKAGE_DIR=$(realpath $SCRIPT_DIR/../packages)
cd $PACKAGE_DIR

cp -R ../skeleton/selenium-server .
sed -i "s/VERSION/$VERSION-$REVISION/" selenium-server/DEBIAN/control
cp $SRC_DIR/$VERSION/$FILE_NAME $PACKAGE_DIR/selenium-server/usr/lib/selenium-server/selenium-server.jar

sudo chown -R root:root *
sudo chmod a+x $PACKAGE_DIR/selenium-server/etc/init.d/selenium-server

# build the packages
sudo dpkg -b selenium-server "selenium-server-$VERSION-$REVISION-amd64.deb"
