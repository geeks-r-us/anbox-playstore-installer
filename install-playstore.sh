#!/bin/bash

# Copyright 2018 root@geeks-r-us.de

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# For further information see: http://geeks-r-us.de/2017/08/26/android-apps-auf-dem-linux-desktop/

# If you find this piece of software useful and or want to support it's development think of 
# buying me a coffee https://www.buymeacoffee.com/YdV7B1rex

# die when an error occurs
set -e

OPENGAPPS_RELEASEDATE="20180903"
OPENGAPPS_FILE="open_gapps-x86_64-7.1-mini-$OPENGAPPS_RELEASEDATE.zip"
OPENGAPPS_URL="https://github.com/opengapps/x86_64/releases/download/$OPENGAPPS_RELEASEDATE/$OPENGAPPS_FILE"

HOUDINI_URL="http://dl.android-x86.org/houdini/7_y/houdini.sfs"
HOUDINI_SO="https://github.com/Rprop/libhoudini/raw/master/4.0.8.45720/system/lib/libhoudini.so"

COMBINEDDIR="/var/snap/anbox/common/combined-rootfs"
OVERLAYDIR="/var/snap/anbox/common/rootfs-overlay"
WORKDIR="$(pwd)/anbox-work"

# check if script was started with BASH
if [ ! "$(ps -p $$ -oargs= | awk '{print $1}' | grep -E 'bash$')" ]; then
   echo "Please use BASH to start the script!"
	 exit 1
fi

# check if user is root
if [ "$(whoami)" != "root" ]; then
	echo "Sorry, you are not root. Please run with sudo $0"
	exit 1
fi

# check if lzip is installed
if [ ! "$(which lzip)" ]; then
	echo -e "lzip is not installed. Please install lzip.\nExample: sudo apt install lzip"
	exit 1
fi

# check if squashfs-tools are installed
if [ ! "$(which mksquashfs)" ] || [ ! "$(which unsquashfs)" ]; then
	echo -e "squashfs-tools is not installed. Please install squashfs-tools.\nExample: sudo apt install squashfs-tools"
	exit 1
else
	MKSQUASHFS=$(which mksquashfs)
	UNSQUASHFS=$(which unsquashfs)
fi

# check if wget is installed
if [ ! "$(which wget)" ]; then
	echo -e "wget is not installed. Please install wget.\nExample: sudo apt install wget"
	exit 1
else
	WGET=$(which wget)
fi

# check if unzip is installed
if [ ! "$(which unzip)" ]; then
	echo -e "unzip is not installed. Please install unzip.\nExample: sudo apt install unzip"
	exit 1
else
	UNZIP=$(which unzip)
fi

# check if tar is installed
if [ ! "$(which tar)" ]; then
	echo -e "tar is not installed. Please install tar.\nExample: sudo apt install tar"
	exit 1
else
	TAR=$(which tar)
fi

# use sudo if installed
if [ ! "$(which sudo)" ]; then
	SUDO=""
else
	SUDO=$(which sudo)
fi


if [ ! -d "$COMBINEDDIR" ]; then
  # enable overlay fs
  $SUDO snap set anbox rootfs-overlay.enable=true
  $SUDO snap restart anbox.container-manager

  sleep 20
fi

echo $OVERLAYDIR
if [ ! -d "$OVERLAYDIR" ]; then
    echo -e "Overlay no enabled ! Please check error messages!"
	exit 1
fi

echo $WORKDIR
if [ ! -d "$WORKDIR" ]; then
    mkdir "$WORKDIR"
fi

cd "$WORKDIR"

if [ -d "$WORKDIR/squashfs-root" ]; then
  $SUDO rm -rf squashfs-root
fi

# get image from anbox
cp /snap/anbox/current/android.img .
$SUDO $UNSQUASHFS android.img

# get opengapps and install it
cd "$WORKDIR"
if [ ! -f ./$OPENGAPPS_FILE ]; then
  $WGET -q --show-progress $OPENGAPPS_URL
  $UNZIP -d opengapps ./$OPENGAPPS_FILE
fi


cd ./opengapps/Core/
for filename in *.tar.lz
do
    $TAR --lzip -xvf ./$filename
done

cd "$WORKDIR"
APPDIR="$OVERLAYDIR/system/priv-app" 
if [ ! -d "$APPDIR" ]; then
	$SUDO mkdir -p "$APPDIR"
fi

$SUDO cp -r ./$(find opengapps -type d -name "PrebuiltGmsCore")					$APPDIR
$SUDO cp -r ./$(find opengapps -type d -name "GoogleLoginService")				$APPDIR
$SUDO cp -r ./$(find opengapps -type d -name "Phonesky")						$APPDIR
$SUDO cp -r ./$(find opengapps -type d -name "GoogleServicesFramework")			$APPDIR

cd "$APPDIR"
$SUDO chown -R 100000:100000 Phonesky GoogleLoginService GoogleServicesFramework PrebuiltGmsCore

# load houdini and spread it
cd "$WORKDIR"
if [ ! -f ./houdini.sfs ]; then
  $WGET -q --show-progress $HOUDINI_URL
  mkdir -p houdini
  $SUDO $UNSQUASHFS -f -d ./houdini ./houdini.sfs
fi

BINDIR="$OVERLAYDIR/system/bin"
if [ ! -d "$BINDIR" ]; then
   $SUDO mkdir -p "$BINDIR"
fi

$SUDO cp -r ./houdini/houdini "$BINDIR/houdini"

$SUDO cp -r ./houdini/xstdata "$BINDIR/"
$SUDO chown -R 100000:100000 "$BINDIR/houdini" "$BINDIR/xstdata"

LIBDIR="$OVERLAYDIR/system/lib"
if [ ! -d "$LIBDIR" ]; then
   $SUDO mkdir -p "$LIBDIR"
fi

$SUDO $WGET -q --show-progress -P "$LIBDIR" $HOUDINI_SO
$SUDO chown -R 100000:100000 "$LIBDIR/libhoudini.so"

$SUDO mkdir -p "$LIBDIR/arm"
$SUDO cp -r ./houdini/linker "$LIBDIR/arm"
$SUDO cp -r ./houdini/*.so "$LIBDIR/arm"
$SUDO cp -r ./houdini/nb "$LIBDIR/arm"

$SUDO chown -R 100000:100000 "$LIBDIR/arm"

# add houdini parser
$SUDO mkdir -p "$OVERLAYDIR/system/etc/binfmt_misc"
echo ":arm_dyn:M::\x7f\x45\x4c\x46\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x28::/system/bin/houdini:" >> "$OVERLAYDIR/system/etc/binfmt_misc/arm_dyn"
echo ":arm_exe:M::\x7f\x45\x4c\x46\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28::/system/bin/houdini:" >> "$OVERLAYDIR/system/etc/binfmt_misc/arm_exe"
$SUDO chown -R 100000:100000 "$OVERLAYDIR/system/etc/binfmt_misc"

# add features
C=$(cat <<-END
  <feature name="android.hardware.touchscreen" />\n
  <feature name="android.hardware.audio.output" />\n
  <feature name="android.hardware.camera" />\n
  <feature name="android.hardware.camera.any" />\n
  <feature name="android.hardware.location" />\n
  <feature name="android.hardware.location.gps" />\n
  <feature name="android.hardware.location.network" />\n
  <feature name="android.hardware.microphone" />\n
  <feature name="android.hardware.screen.portrait" />\n
  <feature name="android.hardware.screen.landscape" />\n
  <feature name="android.hardware.wifi" />\n
  <feature name="android.hardware.bluetooth" />"
END
)


C=$(echo $C | sed 's/\//\\\//g')
C=$(echo $C | sed 's/\"/\\\"/g')

if [ ! -d "$OVERLAYDIR/system/etc/permissions/" ]; then
  $SUDO mkdir -p "$OVERLAYDIR/system/etc/permissions/"
  $SUDO cp "$WORKDIR/squashfs-root/system/etc/permissions/anbox.xml" "$OVERLAYDIR/system/etc/permissions/anbox.xml"
fi

$SUDO sed -i "/<\/permissions>/ s/.*/${C}\n&/" "$OVERLAYDIR/system/etc/permissions/anbox.xml"

# make wifi and bt available
$SUDO sed -i "/<unavailable-feature name=\"android.hardware.wifi\" \/>/d" "$OVERLAYDIR/system/etc/permissions/anbox.xml"
$SUDO sed -i "/<unavailable-feature name=\"android.hardware.bluetooth\" \/>/d" "$OVERLAYDIR/system/etc/permissions/anbox.xml"

if [ ! -x "$OVERLAYDIR/system/build.prop" ]; then
  $SUDO cp "$WORKDIR/squashfs-root/system/build.prop" "$OVERLAYDIR/system/build.prop"
fi

# set processors
ARM_TYPE=",armeabi-v7a,armeabi"
$SUDO sed -i "/^ro.product.cpu.abilist=x86_64,x86/ s/$/${ARM_TYPE}/" "$OVERLAYDIR/system/build.prop"
$SUDO sed -i "/^ro.product.cpu.abilist32=x86/ s/$/${ARM_TYPE}/" "$OVERLAYDIR/system/build.prop"

$SUDO echo "persist.sys.nativebridge=1" >> "$OVERLAYDIR/system/build.prop"

# enable opengles
$SUDO echo "ro.opengles.version=131072" >> "$OVERLAYDIR/system/build.prop"

$SUDO $SUDO snap restart anbox.container-manager
