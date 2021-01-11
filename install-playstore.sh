#!/bin/bash

# Copyright 2019 root@geeks-r-us.de

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
# buying me a coffee https://ko-fi.com/geeks_r_us

# die when an error occurs
set -e

WORKDIR="$(pwd)/anbox-work"

# use sudo if installed
if [ ! "$(which sudo)" ]; then
	SUDO=""
else
	SUDO=$(which sudo)
fi

# clean downloads
if [ "$1" = "--clean" ]; then
   $SUDO rm -rf "$WORKDIR"
   exit 0
fi

# check if script was started with BASH
if [ ! "$(ps -p $$ -oargs= | awk '{print $1}' | grep -E 'bash$')" ]; then
   echo "Please use BASH to start the script!"
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

# check if curl is installed
if [ ! "$(which curl)" ]; then
	echo -e "curl is not installed. Please install curl.\nExample: sudo apt install curl"
	exit 1
else
	CURL=$(which curl)
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



# get latest releasedate based on tag_name for latest x86_64 build
OPENGAPPS_RELEASEDATE="$($CURL -s https://api.github.com/repos/opengapps/x86_64/releases/latest | grep tag_name | grep -o "\"[0-9][0-9]*\"" | grep -o "[0-9]*")"
OPENGAPPS_FILE="open_gapps-x86_64-7.1-pico-$OPENGAPPS_RELEASEDATE.zip"
OPENGAPPS_URL="https://sourceforge.net/projects/opengapps/files/x86_64/$OPENGAPPS_RELEASEDATE/$OPENGAPPS_FILE"

HOUDINI_Y_URL="http://dl.android-x86.org/houdini/7_y/houdini.sfs"
HOUDINI_Z_URL="http://dl.android-x86.org/houdini/7_z/houdini.sfs"

KEYBOARD_LAYOUTS="da_DK de_CH de_DE en_GB en_UK en_US es_ES es_US fr_BE fr_CH fr_FR it_IT nl_NL pt_BR pt_PT ru_RU"

contains() {
	local list="$1"
	local item="$2"
	if [[ "$list" =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
		return 0
	else 
		return 1
	fi
}


if [ "$1" = "--layout" ]; then
	if  ! contains "$KEYBOARD_LAYOUTS" "$2" ; then
		echo "$2 is not a supported keyboard layout. Supported layouts are: $KEYBOARD_LAYOUTS"
		exit 1
	else 
		echo "Keyboard layout $2 selected"
	fi
fi


ANBOX=$(which anbox)
SNAP_TOP=""
if ( [ -d '/var/snap' ] || [ -d '/snap' ] ) && \
	( [ ${ANBOX} = "/snap/bin/anbox" ] || [ ${ANBOX} == /var/lib/snapd/snap/bin/anbox ] );then
	if [ -d '/snap' ];then
		SNAP_TOP=/snap
	else
		SNAP_TOP=/var/lib/snapd/snap
	fi
	COMBINEDDIR="/var/snap/anbox/common/combined-rootfs"
	OVERLAYDIR="/var/snap/anbox/common/rootfs-overlay"
	WITH_SNAP=true
else
	COMBINEDDIR="/var/lib/anbox/combined-rootfs"
	OVERLAYDIR="/var/lib/anbox/rootfs-overlay"
	WITH_SNAP=false
fi

if [ ! -d "$COMBINEDDIR" ]; then
  # enable overlay fs
  	if $WITH_SNAP;then
		$SUDO snap set anbox rootfs-overlay.enable=true
		$SUDO snap restart anbox.container-manager
	else
		$SUDO cat >/etc/systemd/system/anbox-container-manager.service.d/override.conf<<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/anbox container-manager --daemon --privileged --data-path=/var/lib/anbox --use-rootfs-overlay
EOF
		$SUDO systemctl daemon-reload
		$SUDO systemctl restart anbox-container-manager.service
	fi

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
echo "Extracting anbox android image"
# get image from anbox
if $WITH_SNAP;then
	cp $SNAP_TOP/anbox/current/android.img .
else
	cp /var/lib/anbox/android.img .
fi
$SUDO $UNSQUASHFS android.img

if [ "$1" = "--layout" ]; then

	cd "$WORKDIR"
    $WGET -q --show-progress -O anbox-keyboard.kcm -c https://phoenixnap.dl.sourceforge.net/project/androidx86rc2te/Generic_$2.kcm
	$SUDO cp anbox-keyboard.kcm $WORKDIR/squashfs-root/system/usr/keychars/anbox-keyboard.kcm

    if [ ! -d "$OVERLAYDIR/system/usr/keychars/" ]; then
    	$SUDO mkdir -p "$OVERLAYDIR/system/usr/keychars/"
        $SUDO cp "$WORKDIR/squashfs-root/system/usr/keychars/anbox-keyboard.kcm" "$OVERLAYDIR/system/usr/keychars/anbox-keyboard.kcm"
	fi
fi


# get opengapps and install it
cd "$WORKDIR"
echo "Loading open gapps from $OPENGAPPS_URL"
while : ;do
 if [ ! -f ./$OPENGAPPS_FILE ]; then
	 $WGET -q --show-progress $OPENGAPPS_URL
 else
	 $WGET -q --show-progress -c $OPENGAPPS_URL
 fi
 [ $? = 0 ] && break
done
echo "extracting open gapps"

$UNZIP -d opengapps ./$OPENGAPPS_FILE

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

echo "adding lib houdini"

# load houdini_y and spread it
cd "$WORKDIR"
if [ ! -f ./houdini_y.sfs ]; then
  $WGET -O houdini_y.sfs -q --show-progress $HOUDINI_Y_URL
  mkdir -p houdini_y
  $SUDO $UNSQUASHFS -f -d ./houdini_y ./houdini_y.sfs
fi

LIBDIR="$OVERLAYDIR/system/lib"
if [ ! -d "$LIBDIR" ]; then
   $SUDO mkdir -p "$LIBDIR"
fi

$SUDO mkdir -p "$LIBDIR/arm"
$SUDO cp -r ./houdini_y/* "$LIBDIR/arm"
$SUDO chown -R 100000:100000 "$LIBDIR/arm"
$SUDO mv "$LIBDIR/arm/libhoudini.so" "$LIBDIR/libhoudini.so"

# load houdini_z and spread it

if [ ! -f ./houdini_z.sfs ]; then
  $WGET -O houdini_z.sfs -q --show-progress $HOUDINI_Z_URL
  mkdir -p houdini_z
  $SUDO $UNSQUASHFS -f -d ./houdini_z ./houdini_z.sfs
fi

LIBDIR64="$OVERLAYDIR/system/lib64"
if [ ! -d "$LIBDIR64" ]; then
   $SUDO mkdir -p "$LIBDIR64"
fi

$SUDO mkdir -p "$LIBDIR64/arm64"
$SUDO cp -r ./houdini_z/* "$LIBDIR64/arm64"
$SUDO chown -R 100000:100000 "$LIBDIR64/arm64"
$SUDO mv "$LIBDIR64/arm64/libhoudini.so" "$LIBDIR64/libhoudini.so"

# add houdini parser
BINFMT_DIR="/proc/sys/fs/binfmt_misc/register"
set +e
echo ':arm_exe:M::\x7f\x45\x4c\x46\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28::/system/lib/arm/houdini:P' | $SUDO tee -a "$BINFMT_DIR"
echo ':arm_dyn:M::\x7f\x45\x4c\x46\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x28::/system/lib/arm/houdini:P' | $SUDO tee -a "$BINFMT_DIR"
echo ':arm64_exe:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7::/system/lib64/arm64/houdini64:P' | $SUDO tee -a "$BINFMT_DIR"
echo ':arm64_dyn:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\xb7::/system/lib64/arm64/houdini64:P' | $SUDO tee -a "$BINFMT_DIR"

set -e

echo "Modify anbox features"
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

if [ ! -x "$OVERLAYDIR/default.prop" ]; then
  $SUDO cp "$WORKDIR/squashfs-root/default.prop" "$OVERLAYDIR/default.prop"
fi

# set processors
$SUDO sed -i "/^ro.product.cpu.abilist=x86_64,x86/ s/$/,armeabi-v7a,armeabi,arm64-v8a/" "$OVERLAYDIR/system/build.prop"
$SUDO sed -i "/^ro.product.cpu.abilist32=x86/ s/$/,armeabi-v7a,armeabi/" "$OVERLAYDIR/system/build.prop"
$SUDO sed -i "/^ro.product.cpu.abilist64=x86_64/ s/$/,arm64-v8a/" "$OVERLAYDIR/system/build.prop"

echo "persist.sys.nativebridge=1" | $SUDO tee -a "$OVERLAYDIR/system/build.prop"
$SUDO sed -i '/ro.zygote=zygote64_32/a\ro.dalvik.vm.native.bridge=libhoudini.so' "$OVERLAYDIR/default.prop"

# enable opengles
echo "ro.opengles.version=131072" | $SUDO tee -a "$OVERLAYDIR/system/build.prop"

echo "Restart anbox"

if $WITH_SNAP;then
	$SUDO snap restart anbox.container-manager
else
	$SUDO systemctl restart anbox-container-manager.service
fi
