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


#OPENGAPPS_URL="https://github.com/opengapps/x86_64/releases/download/$OPENGAPPS_RELEASEDATE/$OPENGAPPS_FILE"

OPENGAPPS_RELEASEDATE="20190209"
OPENGAPPS_FILE="open_gapps-arm-7.1-mini-$OPENGAPPS_RELEASEDATE.zip"

####SWITCH FOR TESTING#####
OVERLAYDIR="/home/phablet/anbox-data/rootfs"
SYSTEMDIR="/home/phablet/anbox-data"
WORKDIR="/home/phablet/anbox-work"
######
IMGFILE="$SYSTEMDIR/android.img"
APPDIR="$OVERLAYDIR/system/priv-app" 
BINDIR="$OVERLAYDIR/system/bin"
LIBDIR="$OVERLAYDIR/system/lib"
PERMDIR="$OVERLAYDIR/system/etc/permissions/"


#setup google play services +google play permissions after script

#SETUP "Create $WORKDIR with $OPENGAPPS_FILE", run anbox.appmgr once(click settings), install required dependencies, check guide updates, set opengapps release date, testing(recreate anbox-data+anbox-work using new files+device files,check filesystem(unsquashfs -s android.img))

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

if [ ! -f "$SYSTEMDIR/android.img" ]; then
	echo -e "No android.img at $SYSTEMDIR"
	exit 1
fi

if [ ! -d "$WORKDIR" ]; then
	echo -e "Create $WORKDIR with $OPENGAPPS_FILE"
	exit 1
fi

if [ ! -d "$APPDIR" ]; then
	echo -e "$OVERLAYDIR doesn't contain $APPDIR!"
	exit 1
fi

if [ ! -d "$BINDIR" ]; then
	echo -e "$OVERLAYDIR doesn't contain $BINDIR!"
	exit 1
fi

if [ ! -d "$PERMDIR" ]; then
	echo -e "$OVERLAYDIR doesn't contain $PERMDIR!"
	exit 1
fi

if [ ! -d "$LIBDIR" ]; then
	echo -e "$OVERLAYDIR doesn't contain $LIBDIR!"
	exit 1
fi

if [ ! -f "$WORKDIR/$OPENGAPPS_FILE" ]; then
	echo -e "Place $OPENGAPPS_FILE in $WORKDIR"
	exit 1
fi

if [ ! -d "$OVERLAYDIR" ]; then
	echo -e "Anbox-data/rootfs folder not found at $OVERLAYDIR"
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

$SUDO anbox-tool disable
sudo mount -o rw,remount /

cd "$WORKDIR"

if [ -d "$WORKDIR/squashfs-root" ]; then
  $SUDO rm -rf squashfs-root
fi

#get image from anbox
cp "$SYSTEMDIR/android.img" .
$SUDO $UNSQUASHFS android.img

# get opengapps and install it
cd "$WORKDIR"
$UNZIP -d opengapps ./$OPENGAPPS_FILE

cd ./opengapps/Core/
for filename in *.tar.lz
do
    $TAR --lzip -xvf ./$filename
done

cd "$WORKDIR"

APPDIR="$WORKDIR/squashfs-root/system/priv-app"

$SUDO cp -r ./$(find opengapps -type d -name "PrebuiltGmsCore")					$APPDIR
$SUDO cp -r ./$(find opengapps -type d -name "GoogleLoginService")				$APPDIR
$SUDO cp -r ./$(find opengapps -type d -name "Phonesky")						$APPDIR
$SUDO cp -r ./$(find opengapps -type d -name "GoogleServicesFramework")			$APPDIR

cd "$APPDIR"
$SUDO chown -R 100000:100000 Phonesky GoogleLoginService GoogleServicesFramework PrebuiltGmsCore

cd "$WORKDIR"
mv android.img androidbackup.img
sudo mksquashfs squashfs-root android.img -comp xz -no-xattrs -b 131072 -Xbcj arm
sudo rm -r squashfs-root
sudo cp android.img "$SYSTEMDIR"
sudo chown root:root "$SYSTEMDIR/android.img"
sudo rm android.img
sudo mount -o ro,remount /
$SUDO anbox-tool enable
