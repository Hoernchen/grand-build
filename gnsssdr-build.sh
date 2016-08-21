#!/bin/bash
#
# Copyright 2016 Free Software Foundation, Inc.
#
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU Radio; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.


# Known dependencies:
#  - cmake, git, make, xutils-dev, automake, autoconf, libtool, wget, perl, tar, sed
# Need to have installed Android Studio, Android SDK, and Android NDK
#
# Tested only on Ubuntu 15.10, 64-bit



if [ -z "$PREFIX" ];
then
    echo "PREFIX not set;"
    exit
fi

if [ -z "$ANDROID_SDK" ];
then
    echo "Please set ANDROID_SDK to point to the location of the Android SDK (e.g., /opt/android)"
    exit
fi

if [ -z "$ANDROID_NDK" ];
then
    echo "Please set ANDROID_NDK to point to the location of the Android NDK (e.g., /opt/ndk)"
    exit
fi

if [ -z "$PARALLEL" ];
then
    echo "Parellelism is unset; setting to 1"
    PARALLEL=1
fi

set -e

echo "Asking for sudo permissions to create prefix directory ${PREFIX}"
sudo mkdir -p ${PREFIX}
sudo mkdir -p $PREFIX/lib/
sudo chown $USER:$USER -R ${PREFIX}
sudo -K # invalidates credentials for anyone paranoid

ANDROID_MIN_API_VERSION=21
ANDROID_STANDALONE_TOOLCHAIN=${PREFIX}/android-toolchain
PATH_ORIG=$PATH
PATH=$ANDROID_STANDALONE_TOOLCHAIN/bin:$ANDROID_SDK/tools:$ANDROID_NDK:$PATH
TOP_BUILD_DIR=`pwd`

#### build ndk master
#### building the ndk needs pkg TEXINFO for makeinfo!!!
#mkdir bin
#PATH=`pwd`/bin:$PATH
#curl https://storage.googleapis.com/git-repo-downloads/repo > ./bin/repo
#chmod a+x ./bin/repo
#mkdir ndk
#cd ndk
#repo init -u https://android.googlesource.com/platform/manifest -b master-ndk
#repo sync
#cd ndk
#./checkbuild.py

###########################
###crystax ndk fixes #########
###########################

### this doesn't play well with android.toolchain.cmake version parsing
#rm ${ANDROID_NDK}/RELEASE.txt || true

## sched fuckup in crystax 10.3.1
## https://groups.google.com/forum/#!topic/crystax-ndk/W84bE09LtiU
## https://github.com/crystax/android-platform-bionic/commit/9041d6a287d202c78b7bb888da2e4c93b44ee19e
## ${ANDROID_NDK}/platforms/android-21/arch-arm/usr/include/crystax/bionic/libc/include/mangled-sched.h


## cheap fix for libcrystax dep
#cp -a ${ANDROID_NDK}/sources/crystax/libs/armeabi-v7a/libcrystax.so ${ANDROID_NDK}/platforms/android-21/arch-arm/usr/lib/
#cp -a ${ANDROID_NDK}/sources/crystax/libs/armeabi-v7a/libcrystax.a ${ANDROID_NDK}/platforms/android-21/arch-arm/usr/lib/
#cp -a ${ANDROID_NDK}/sources/crystax/libs/armeabi-v7a/libcrystax.a ${ANDROID_NDK}/platforms/android-18/arch-arm/usr/lib/
#cp -a ${ANDROID_NDK}/sources/crystax/libs/armeabi-v7a/libcrystax.so ${ANDROID_NDK}/platforms/android-18/arch-arm/usr/lib/

#cp -a ${ANDROID_NDK}/sources/boost/1.59.0/include/ ${PREFIX}
#cp -a ${ANDROID_NDK}/sources/boost/1.59.0/libs/armeabi-v7a/gnu-4.9/* ${PREFIX}/lib/

###### end crystax fixes

${ANDROID_NDK}/build/tools/make-standalone-toolchain.sh --toolchain=arm-linux-androideabi-clang --stl=libc++ --arch=arm --platform=android-${ANDROID_MIN_API_VERSION} --abis=armeabi-v7a --install-dir=${ANDROID_STANDALONE_TOOLCHAIN}

#new android toolchain has python script
#python ${ANDROID_NDK}/build/tools/make_standalone_toolchain.py --force --stl=gnustl --arch=arm --api=21 --install-dir=${ANDROID_STANDALONE_TOOLCHAIN}

#unset ANDROID_NDK --standalone toolchain?

## fix linking issues: shared/static prefix, -stdlib=
## the standalone toolchain has a renamed runtime, but the ndk doesn't -> better safe than sorry
## also libm fuckup...
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/libs/
cd $PREFIX/libs/
ln -sfn ../lib armeabi-v7a
cd $TOP_BUILD_DIR
cd $PREFIX/lib
cp -a ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a/libc++_shared.so .
cp -a ${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a/libc++_shared.so libc++.so
cp -a ${ANDROID_NDK}/platforms/android-23/arch-arm/usr/lib/libm.so .
#ln -s libc++_shared.so libc++.so || true
cd $TOP_BUILD_DIR



TOOLCHAIN=`pwd`/AndroidToolchain.cmake

#. scripts/boost.sh
#. scripts/fftw.sh
#. scripts/openssl.sh
#.  scripts/zmq.sh
#.  scripts/gnuradio-download.sh
#.  scripts/libusb.sh
#.  scripts/rtlsdr.sh
#.  scripts/uhd.sh
#.  scripts/volk.sh
#.  scripts/gnuradio.sh
#.  scripts/gr-grand.sh
#.  scripts/gr-osmosdr.sh
#.  scripts/gmp.sh
#.  scripts/nettle.sh
#. scripts/gnutls.sh
#. scripts/openblas.sh
#. scripts/clapack.sh
#. scripts/armadillo.sh
#. scripts/gflags.sh
#. scripts/glog.sh
#. scripts/gnsssdr_volk.sh
#. scripts/gnss-sdr.sh

#############################################################
###                   BOOST DEPENDENCY
#############################################################

echo ""; echo ""; echo ""; echo ""

BOOST_VER=1.61.0
BOOST_DIR=boost_1_61_0
BOOST_URL="http://jaist.dl.sourceforge.net/project/boost/boost/1.61.0/boost_1_61_0.tar.bz2"

if [ -e "${BOOST_DIR}.tar.bz2" ];
then
    echo "Boost file already downloaded; skipping"
else
    echo "Downloading Boost tarball"
    wget ${BOOST_URL}
fi

if [ -d ${BOOST_DIR} ];
then
    echo "Boost directory expanded; skipping"
else
    echo "Expanding Boost tarball"
    tar xjf ${BOOST_DIR}.tar.bz2
    chmod +r -R ${BOOST_DIR}
fi

cd ${BOOST_DIR}
echo "import os ;

local ANDROID_STANDALONE_TOOLCHAIN = [ os.environ ANDROID_STANDALONE_TOOLCHAIN ] ;

using gcc : android :
     ${ANDROID_STANDALONE_TOOLCHAIN}/bin/clang++ :
     <compileflags>--std=gnu++11
     <compileflags>--sysroot=${ANDROID_STANDALONE_TOOLCHAIN}/sysroot
     <compileflags>-march=armv7-a
     <compileflags>-mfloat-abi=softfp
     <compileflags>-Os
     <compileflags>-fno-strict-aliasing
     <compileflags>-O2
     <compileflags>-DNDEBUG
     <compileflags>-g
     <compileflags>-lc++_shared
     <compileflags>-I${ANDROID_STANDALONE_TOOLCHAIN}/include/c++/4.9/
     <compileflags>-I${ANDROID_STANDALONE_TOOLCHAIN}/include/c++/4.9/arm-linux-androideabi/armv7-a
     <compileflags>-D__GLIBC__
     <compileflags>-D_GLIBCXX__PTHREADS
     <compileflags>-D__arm__
     <compileflags>-D_REENTRANT
     <compileflags>-DBOOST_SP_USE_PTHREADS
     <compileflags>-L${ANDROID_STANDALONE_TOOLCHAIN}/lib/gcc/arm-linux-androideabi/4.9/
     <archiver>${ANDROID_STANDALONE_TOOLCHAIN}/bin/arm-linux-androideabi-ar
     <ranlib>${ANDROID_STANDALONE_TOOLCHAIN}/bin/arm-linux-androideabi-ranlib
     ;" > tools/build/src/user-config.jam

echo "Boostrapping and Building"
./bootstrap.sh
./b2 \
  --without-python --without-container --without-context \
  --without-coroutine --without-coroutine2 --without-graph --without-graph_parallel \
  --without-iostreams --without-locale --without-log --without-math \
  --without-mpi --without-signals --without-timer --without-wave \
  link=static runtime-link=static threading=multi threadapi=pthread \
  toolset=clang target-os=android --stagedir=android --build-dir=android variant=release \
  stage -j 4

echo "Installing"
./b2 \
  --without-python --without-container --without-context \
  --without-coroutine --without-coroutine2 --without-graph --without-graph_parallel \
  --without-iostreams --without-locale --without-log --without-math \
  --without-mpi --without-signals --without-timer --without-wave \
  link=static runtime-link=static threading=multi threadapi=pthread \
  toolset=clang target-os=android --stagedir=android --build-dir=android variant=release \
  --prefix=$PREFIX install -j 4

cd ${TOP_BUILD_DIR}


##############################################################
####                   FFTW DEPENDENCY
##############################################################

echo ""; echo ""; echo ""; echo ""

FFTW_VER=3.3.4
FFTW_DIR=fftw-${FFTW_VER}
FFTW_URL="http://www.fftw.org/${FFTW_DIR}.tar.gz"

if [ -e "${FFTW_DIR}.tar.gz" ];
then
    echo "FFTW file already downloaded; skipping"
else
    echo "Downloading FFTW tarball"
    wget ${FFTW_URL}
fi

if [ -d ${FFTW_DIR} ];
then
    echo "FFTW directory expanded; skipping"
else
    echo "Expanding FFTW tarball"
    tar xzf ${FFTW_DIR}.tar.gz
    chmod +r -R ${FFTW_DIR}
fi

cd ${FFTW_DIR}

mkdir -p build
cd build

export SYS_ROOT="$ANDROID_STANDALONE_TOOLCHAIN/sysroot"
export CC="clang --sysroot=$SYS_ROOT"
export LD="arm-linux-androideabi-ld"
export AR="arm-linux-androideabi-ar"
export RANLIB="arm-linux-androideabi-ranlib"
export STRIP="arm-linux-androideabi-strip"

echo ""; echo ""
echo "Configuring FFTW"
../configure --enable-single --enable-static --enable-threads \
  --enable-float  --enable-neon \
  --host=armv7-eabi --build=x86_64-linux \
  --prefix=$PREFIX \
  LIBS="-lc -lgcc -march=armv7-a -mfloat-abi=softfp -mfpu=neon" \
  CC="clang -march=armv7-a -mfloat-abi=softfp -mfpu=neon"

echo "\n\nBuilding and installing FFTW"
make -s -j${PARALLEL}
make -s install

unset SYS_ROOT
unset CC
unset LD
unset AR
unset RANLIB
unset STRIP

cd ${TOP_BUILD_DIR}

#############################################################
###            OpenSSL (libcrypto) DEPENDENCY
#############################################################

echo ""; echo ""; echo ""; echo ""

# Crete a new environment that will screw with the normal one
PATH_OLD=$PATH

PATH=$ANDROID_NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$PATH_ORIG
ANDROID_NDK_ROOT=$ANDROID_NDK

echo $PATH

OPENSSL_VER=1.0.2
OPENSSL_VER_PATCH=a
OPENSSL_DIR=openssl-${OPENSSL_VER}${OPENSSL_VER_PATCH}
OPENSSL_URL="ftp://ftp.openssl.org/source/old/${OPENSSL_VER}/${OPENSSL_DIR}.tar.gz"

if [ -e "${OPENSSL_DIR}.tar.gz" ];
then
    echo "OpenSSL file already downloaded; skipping"
else
    echo "Downloading OpenSSL tarball"
    wget ${OPENSSL_URL}
fi

if [ -d ${OPENSSL_DIR} ];
then
    echo "OpenSSL directory expanded; skipping"
else
    echo "Expanding OpenSSL tarball"
    tar xzf ${OPENSSL_DIR}.tar.gz
    chmod +r -R ${OPENSSL_DIR}
fi

cd ${OPENSSL_DIR}


### FIXME this sets android api to 18, but we want 21...
wget https://wiki.openssl.org/images/7/70/Setenv-android.sh
chmod +x Setenv-android.sh
. ./Setenv-android.sh _ANDROID_API=21
perl -pi -e 's/install: all install_docs install_sw/install: install_docs install_sw/g' Makefile.org
./config --prefix=/usr shared no-ssl2 no-ssl3 no-comp no-hw no-engines --openssldir=$ANDROID_STANDALONE_TOOLCHAIN/sysroot/usr/ssl/$ANDROID_API

echo ""; #echo ""
echo "Making and installing OpenSSL"
make depend
make all

echo ""; echo ""
echo "Copying and linking OpenSSL files"
cp -fv libcrypto.* $ANDROID_STANDALONE_TOOLCHAIN/sysroot/usr/lib
cp -fv libssl.* $ANDROID_STANDALONE_TOOLCHAIN/sysroot/usr/lib/
mkdir -p $ANDROID_STANDALONE_TOOLCHAIN/sysroot/usr/include
cp -rLfv include/openssl $ANDROID_STANDALONE_TOOLCHAIN/sysroot/usr/include

# reset our path
PATH=$PATH_OLD

cd ${TOP_BUILD_DIR}


##############################################################
####          ZEROMQ DEPENDENCY
##############################################################

echo ""; echo ""; echo ""; echo ""

ZEROMQ_VER=3.2.4
ZEROMQ_DIR=zeromq-${ZEROMQ_VER}
ZEROMQ_URL="http://download.zeromq.org/${ZEROMQ_DIR}.tar.gz"

if [ -e "${ZEROMQ_DIR}.tar.gz" ];
then
    echo "ZEROMQ file already downloaded; skipping"
else
    echo "Downloading ZEROMQ tarball"
    wget ${ZEROMQ_URL}
fi

if [ -d ${ZEROMQ_DIR} ];
then
    echo "ZEROMQ directory expanded; skipping"
else
    echo "Expanding ZEROMQ tarball"
    tar xzf ${ZEROMQ_DIR}.tar.gz
    chmod +r -R ${ZEROMQ_DIR}
    sed -e 's/libzmq_werror="yes"/libzmq_werror="no"/' -i ${ZEROMQ_DIR}/configure
    sed -i '25 a #include <time.h>' ${ZEROMQ_DIR}/tests/test_connect_delay.cpp 
fi

cd ${ZEROMQ_DIR}



echo ""; echo ""
echo "Configuring ZMQ"
./configure --enable-static --disable-shared --host=arm-linux-androideabi \
    --prefix=$PREFIX LDFLAGS="-L$OUTPUT_DIR/lib \
    -L$ANDROID_STANDALONE_TOOLCHAIN/arm-linux-androideabi/lib/armv7-a \
    -L${ANDROID_NDK}/sources/cxx-stl/llvm-libc++/libs/armeabi-v7a \
    -lc++_shared" CPPFLAGS="-fPIC -I$PREFIX/include \
    -I$ANDROID_STANDALONE_TOOLCHAIN/include/c++/4.9/arm-linux-androideabi/armv7-a" \
    LIBS="-lgcc" --with-libsodium=no CXX=clang++ CC=clang

echo ""; echo ""
echo "Building and installing ZMQ"
make -s -j${PARALLEL}
make -s install

echo ""; echo ""
echo "Getting C++ Header for ZMQ"
wget -O $PREFIX/include/zmq.hpp https://raw.githubusercontent.com/zeromq/cppzmq/master/zmq.hpp

cd ${TOP_BUILD_DIR}

##############################################################
####          DOWNLOAD GNURADIO
##############################################################

echo ""; echo ""; echo ""; echo ""

GNURADIO_DIR=gnuradio

if [ -e "${GNURADIO_DIR}" ];
then
    echo "GNURADIO file already cloned; skipping"
    cd gnuradio
else
    echo "Git cloning GNURADIO"
    git clone git://git.gnuradio.org/gnuradio.git
    
    cd gnuradio
	git checkout android
	rm cmake/Toolchains/AndroidToolchain.cmake
	#wget -O cmake/Toolchains/AndroidToolchain.cmake https://raw.githubusercontent.com/chenxiaolong/android-cmake/mbp/android.toolchain.cmake
	#https://raw.githubusercontent.com/urho3d/Urho3D/master/CMake/Toolchains/android.toolchain.cmake
	# old: https://raw.githubusercontent.com/taka-no-me/android-cmake/master/android.toolchain.cmake
fi



#TOOLCHAIN=`pwd`/cmake/Toolchains/AndroidToolchain.cmake
cd ${TOP_BUILD_DIR}

#TOOLCHAIN=`pwd`/AndroidToolchain.cmake


##############################################################
####          LIBUSB DEPENDENCY
##############################################################

echo ""; echo ""; echo ""; echo ""

LIBUSB_DIR=libusb-android
LIBUSB_VER=v1.0.19-and5

if [ -e "${LIBUSB_DIR}" ];
then
    echo "LIBUSB file already cloned; skipping"
else
    echo "Git cloning LIBUSB"
    git clone https://github.com/Hoernchen/${LIBUSB_DIR}
fi

cd ${LIBUSB_DIR}
git checkout ${LIBUSB_VER}

#broken due to linking with stdlibc++
#echo "Building libUSB via ndk-build"
#cd android/jni
#ndk-build APP_STL=c++_shared NDK_TOOLCHAIN_VERSION=clang

${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/clang -gcc-toolchain ${ANDROID_NDK}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64 -fpic -ffunction-sections -funwind-tables -fstack-protector-strong -Wno-invalid-command-line-argument -Wno-unused-command-line-argument -no-canonical-prefixes -fno-integrated-as -g -target armv7-none-linux-androideabi -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -mthumb -Os -DNDEBUG  -I/$PWD/android/jni/.. -I/$PWD/android/jni/../../libusb -I/$PWD/android/jni/../../libusb/os -I/$PWD/android/jni -DANDROID  -Wa,--noexecstack -Wformat -Werror=format-security    -isystem ${ANDROID_NDK}/platforms/android-9/arch-arm/usr/include -Wl,-soname,libusb1.0.so -shared --sysroot=${ANDROID_NDK}/platforms/android-9/arch-arm -lgcc  -no-canonical-prefixes -target armv7-none-linux-androideabi -Wl,--fix-cortex-a8  -Wl,--build-id -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--warn-shared-textrel -Wl,--fatal-warnings -llog  -L${ANDROID_NDK}/platforms/android-9/arch-arm/usr/lib -llog -lc -lm libusb/core.c libusb/descriptor.c libusb/hotplug.c libusb/io.c libusb/sync.c libusb/strerror.c libusb/os/linux_usbfs.c libusb/os/poll_posix.c libusb/os/threads_posix.c libusb/os/linux_netlink.c -o libusb1.0.so
${ANDROID_NDK}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-strip --strip-unneeded  libusb1.0.so

echo "Copying libUSB files to $PREFIX"
cp -Lfv ${TOP_BUILD_DIR}/${LIBUSB_DIR}/libusb1.0.so $PREFIX/lib
cp -rLfv ${TOP_BUILD_DIR}/${LIBUSB_DIR}/libusb $PREFIX/include

cd ${TOP_BUILD_DIR}

############################################################
##          RTLSDR DEPENDENCY
############################################################

echo ""; echo ""; echo ""; echo ""

RTLSDR_DIR=rtl-sdr
#RTLSDR_VER=android5

if [ -e "${RTLSDR_DIR}" ];
then
    echo "RTLSDR file already cloned; skipping"
    cd ${RTLSDR_DIR}
	#git checkout ${RTLSDR_VER}

else
    echo "Git cloning RTLSDR"
#    git clone https://github.com/trondeau/${RTLSDR_DIR}
#	git clone git://git.osmocom.org/rtl-sdr
 
	git clone  https://github.com/Hoernchen/rtl-sdr.git
    
    cd ${RTLSDR_DIR}
#	git checkout ${RTLSDR_VER}

	#get rid of set(THREADS_USE_PTHREADS_WIN32 true)
#	sed -i -e '65d;' CMakeLists.txt

	#no tools either
#	sed -i -e '87,134d;' src/CMakeLists.txt
#	sed -i "106i set(INSTALL_TARGETS rtlsdr_shared rtlsdr_static)" src/CMakeLists.txt
fi


echo ""; echo ""
echo "Configuring RTL-SDR"
mkdir -p build
cd build

set +e # expecting this call to cmake to fail
cmake -Wno-dev \
	-DANDROID_NATIVE_API_LEVEL=21 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
      -DLIBUSB_INCLUDE_DIR=$PREFIX/include/libusb \
      -DLIBUSB_LIBRARIES=$PREFIX/lib/libusb1.0.so \
      ../

set -e
cmake -Wno-dev \
	-DANDROID_NATIVE_API_LEVEL=21 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
      -DLIBUSB_INCLUDE_DIR=$PREFIX/include/libusb \
      -DLIBUSB_LIBRARIES=$PREFIX/lib/libusb1.0.so \
      ../

echo ""; echo ""
echo "Building and installing RTL-SDR"
make -s -j${PARALLEL}
make -s install

cd ${TOP_BUILD_DIR}

###########################################################
#          UHD DEPENDENCY
###########################################################

echo ""; echo ""; echo ""; echo ""

UHD_DIR=uhd
UHD_VER=android

if [ -e "${UHD_DIR}" ];
then
    echo "UHD file already cloned; skipping"
else
    echo "Git cloning UHD"
    git clone https://github.com/Hoernchen/${UHD_DIR}
fi

cd ${UHD_DIR}/host
git checkout ${UHD_VER}

echo ""; echo ""
echo "Configuring UHD"
mkdir -p build
cd build
#	-DBoost_Debug=1
cmake -Wno-dev \
	-DANDROID_NATIVE_API_LEVEL=21 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DBOOST_ROOT=$PREFIX \
      -DBoost_DIR=$PREFIX \
      -DBoost_INCLUDE_DIR=$PREFIX/include \
      -DBOOST_LIBRARYDIR=$PREFIX/lib \
      -DBoost_USE_STATIC_LIBS=True \
	-DBoost_ATOMIC_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_atomic.a \
	-DBoost_ATOMIC_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_atomic.a \
	-DBoost_CHRONO_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_chrono.a \
	-DBoost_CHRONO_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_chrono.a \
	-DBoost_DATE_TIME_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_date_time.a \
	-DBoost_DATE_TIME_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_date_time.a \
	-DBoost_FILESYSTEM_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_filesystem.a \
	-DBoost_FILESYSTEM_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_filesystem.a \
	-DBoost_INCLUDE_DIR:PATH=$PREFIX/include \
	-DBoost_LIBRARY_DIR_DEBUG:PATH=$PREFIX/lib \
	-DBoost_LIBRARY_DIR_RELEASE:PATH=$PREFIX/lib \
	-DBoost_PROGRAM_OPTIONS_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_program_options.a \
	-DBoost_PROGRAM_OPTIONS_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_program_options.a \
	-DBoost_REGEX_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_regex.a \
	-DBoost_REGEX_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_regex.a \
	-DBoost_SERIALIZATION_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_serialization.a \
	-DBoost_SERIALIZATION_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_serialization.a \
	-DBoost_SYSTEM_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_system.a \
	-DBoost_SYSTEM_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_system.a \
	-DBoost_THREAD_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_thread.a \
	-DBoost_THREAD_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_thread.a \
	-DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_unit_test_framework.a \
	-DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_unit_test_framework.a \
      -DLIBUSB_INCLUDE_DIRS=$PREFIX/include/libusb \
      -DLIBUSB_LIBRARIES=$PREFIX/lib/libusb1.0.so \
      -DPYTHON_EXECUTABLE=/usr/bin/python \
      -DENABLE_STATIC_LIBS=True -DENABLE_USRP1=False \
      -DENABLE_USRP2=False -DENABLE_B100=False \
      -DENABLE_X300=False -DENABLE_OCTOCLOCK=False \
      -DENABLE_TESTS=False -DENABLE_ORC=False \
      ../

echo ""; echo ""
echo "Building and installing UHD"
make -s -j${PARALLEL}
make -s install

cd ${TOP_BUILD_DIR}

###########################################################
#          VOLK DEPENDENCY
###########################################################

echo ""; echo ""; echo ""; echo ""

VOLK_DIR=volk
VOLK_VER=android

if [ -e "${VOLK_DIR}" ];
then
    echo "VOLK file already cloned; skipping"
else
    echo "Git cloning VOLK"
    git clone https://github.com/Hoernchen/${VOLK_DIR}
fi

cd ${VOLK_DIR}
git checkout ${VOLK_VER}

echo ""; echo ""
echo "Configuring VOLK"
mkdir -p build
cd build
cmake -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release \
	-DANDROID=1 \
	-DANDROID_NATIVE_API_LEVEL=23 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
	-DBoost_ATOMIC_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_atomic.a \
	-DBoost_ATOMIC_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_atomic.a \
	-DBoost_CHRONO_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_chrono.a \
	-DBoost_CHRONO_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_chrono.a \
	-DBoost_DATE_TIME_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_date_time.a \
	-DBoost_DATE_TIME_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_date_time.a \
	-DBoost_FILESYSTEM_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_filesystem.a \
	-DBoost_FILESYSTEM_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_filesystem.a \
	-DBoost_INCLUDE_DIR:PATH=$PREFIX/include \
	-DBoost_LIBRARY_DIR_DEBUG:PATH=$PREFIX/lib \
	-DBoost_LIBRARY_DIR_RELEASE:PATH=$PREFIX/lib \
	-DBoost_PROGRAM_OPTIONS_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_program_options.a \
	-DBoost_PROGRAM_OPTIONS_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_program_options.a \
	-DBoost_REGEX_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_regex.a \
	-DBoost_REGEX_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_regex.a \
	-DBoost_SERIALIZATION_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_serialization.a \
	-DBoost_SERIALIZATION_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_serialization.a \
	-DBoost_SYSTEM_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_system.a \
	-DBoost_SYSTEM_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_system.a \
	-DBoost_THREAD_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_thread.a \
	-DBoost_THREAD_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_thread.a \
	-DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_unit_test_framework.a \
	-DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_unit_test_framework.a \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
      -DPYTHON_EXECUTABLE=/usr/bin/python \
      ../

#      -DENABLE_STATIC_LIBS=True
echo ""; echo ""
echo "Building and installing VOLK"
make -s -j${PARALLEL}
make -s install

cd ${TOP_BUILD_DIR}

###########################################################
#          BUILDING GNURADIO
###########################################################

cd gnuradio

echo ""; echo ""
echo ${PATH}
echo "Configuring GNU Radio"
mkdir -p build
cd build

export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=${PREFIX}/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SYS_ROOT}

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -Wno-dev \
	-DANDROID_NATIVE_API_LEVEL=23 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
	-DBoost_ATOMIC_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_atomic.a \
	-DBoost_ATOMIC_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_atomic.a \
	-DBoost_CHRONO_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_chrono.a \
	-DBoost_CHRONO_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_chrono.a \
	-DBoost_DATE_TIME_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_date_time.a \
	-DBoost_DATE_TIME_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_date_time.a \
	-DBoost_FILESYSTEM_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_filesystem.a \
	-DBoost_FILESYSTEM_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_filesystem.a \
	-DBoost_INCLUDE_DIR:PATH=$PREFIX/include \
	-DBoost_LIBRARY_DIR_DEBUG:PATH=$PREFIX/lib \
	-DBoost_LIBRARY_DIR_RELEASE:PATH=$PREFIX/lib \
	-DBoost_PROGRAM_OPTIONS_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_program_options.a \
	-DBoost_PROGRAM_OPTIONS_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_program_options.a \
	-DBoost_REGEX_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_regex.a \
	-DBoost_REGEX_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_regex.a \
	-DBoost_SERIALIZATION_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_serialization.a \
	-DBoost_SERIALIZATION_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_serialization.a \
	-DBoost_SYSTEM_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_system.a \
	-DBoost_SYSTEM_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_system.a \
	-DBoost_THREAD_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_thread.a \
	-DBoost_THREAD_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_thread.a \
	-DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_unit_test_framework.a \
	-DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_unit_test_framework.a \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
    -DENABLE_INTERNAL_VOLK=Off \
    -DBOOST_ROOT=$PREFIX \
    -DFFTW3F_INCLUDE_DIRS=$PREFIX/include \
    -DFFTW3F_LIBRARIES=$PREFIX/lib/libfftw3f.a \
    -DFFTW3F_THREADS_LIBRARIES=$PREFIX/lib/libfftw3f_threads.a \
    -DVOLK_LIBRARIES=${PREFIX}/lib/libvolk.so \
    -DVOLK_INCLUDE_DIRS=${PREFIX}/include/volk \
    -DUHD_LIBRARIES=${PREFIX}/lib/libuhd.so \
    -DUHD_INCLUDE_DIRS=${PREFIX}/include/uhd \
    -DENABLE_DEFAULT=False \
    -DENABLE_GR_LOG=False \
    -DENABLE_VOLK=True \
    -DENABLE_GNURADIO_RUNTIME=True \
    -DENABLE_GR_BLOCKS=True \
    -DENABLE_GR_FEC=True \
    -DENABLE_GR_TRELLIS=True \
    -DENABLE_GR_FFT=True \
    -DENABLE_GR_FILTER=True \
    -DENABLE_GR_ANALOG=True \
    -DENABLE_GR_DIGITAL=True \
    -DENABLE_GR_CHANNELS=True \
    -DENABLE_GR_ZEROMQ=True \
    -DENABLE_GR_UHD=True \
    -DENABLE_STATIC_LIBS=True \
    -DENABLE_GR_CTRLPORT=True \
    -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
    -DPYTHON_EXECUTABLE=/usr/bin/python \
    ../

echo ""; echo ""
echo "Building and installing GNU Radio"
make -j${PARALLEL}
make install

cd ${TOP_BUILD_DIR}

############################################################
##          GRAnd
############################################################

echo ""; echo ""; echo ""; echo ""

GRAND_DIR=gr-grand
GRAND_VER=master

if [ -e "${GRAND_DIR}" ];
then
    echo "gr-grand file already cloned; skipping"
else
    echo "Git cloning gr-grand"
    git clone https://github.com/Hoernchen/${GRAND_DIR}
    
    #no cppunit for now
#	sed -i -e '106d;' ${GRAND_DIR}/CMakeLists.txt
#	sed -i -e '115,117d;' ${GRAND_DIR}/CMakeLists.txt
#	sed -i -e '134d;' ${GRAND_DIR}/CMakeLists.txt
#	sed -i '60s/system/system thread/' ${GRAND_DIR}/CMakeLists.txt
fi

cd ${GRAND_DIR}
git checkout ${GRAND_VER}



echo ""; echo ""
echo "Configuring GRAND"
mkdir -p build
cd build
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
cmake -Wno-dev \
	-DANDROID_NATIVE_API_LEVEL=21 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
		-DBoost_ATOMIC_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_atomic.a \
	-DBoost_ATOMIC_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_atomic.a \
	-DBoost_CHRONO_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_chrono.a \
	-DBoost_CHRONO_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_chrono.a \
	-DBoost_DATE_TIME_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_date_time.a \
	-DBoost_DATE_TIME_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_date_time.a \
	-DBoost_FILESYSTEM_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_filesystem.a \
	-DBoost_FILESYSTEM_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_filesystem.a \
	-DBoost_INCLUDE_DIR:PATH=$PREFIX/include \
	-DBoost_LIBRARY_DIR_DEBUG:PATH=$PREFIX/lib \
	-DBoost_LIBRARY_DIR_RELEASE:PATH=$PREFIX/lib \
	-DBoost_PROGRAM_OPTIONS_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_program_options.a \
	-DBoost_PROGRAM_OPTIONS_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_program_options.a \
	-DBoost_REGEX_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_regex.a \
	-DBoost_REGEX_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_regex.a \
	-DBoost_SERIALIZATION_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_serialization.a \
	-DBoost_SERIALIZATION_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_serialization.a \
	-DBoost_SYSTEM_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_system.a \
	-DBoost_SYSTEM_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_system.a \
	-DBoost_THREAD_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_thread.a \
	-DBoost_THREAD_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_thread.a \
	-DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_unit_test_framework.a \
	-DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_unit_test_framework.a \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DPYTHON_EXECUTABLE=/usr/bin/python -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config\
      ../

echo ""; echo ""
echo "Building and installing gr-grand"
make -s -j${PARALLEL}
make -s install

cd ${TOP_BUILD_DIR}

############################################################
##          GR-OSMOSDR DEPENDENCY
############################################################

echo ""; echo ""; echo ""; echo ""

OSMOSDR_DIR=gr-osmosdr
OSMOSDR_VER=android5

if [ -e "${OSMOSDR_DIR}" ];
then
    echo "gr-osmosdr file already cloned; skipping"
else
    echo "Git cloning gr-osmosdr"
    git clone https://github.com/Hoernchen/${OSMOSDR_DIR}
fi

cd ${OSMOSDR_DIR}
git checkout ${OSMOSDR_VER}

echo ""; echo ""
echo "Configuring OSMOSDR"
mkdir -p build
cd build
#PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SYS_ROOT}

cmake -Wno-dev \
	-DANDROID_NATIVE_API_LEVEL=21 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
	-DBoost_ATOMIC_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_atomic.a \
	-DBoost_ATOMIC_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_atomic.a \
	-DBoost_CHRONO_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_chrono.a \
	-DBoost_CHRONO_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_chrono.a \
	-DBoost_DATE_TIME_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_date_time.a \
	-DBoost_DATE_TIME_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_date_time.a \
	-DBoost_FILESYSTEM_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_filesystem.a \
	-DBoost_FILESYSTEM_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_filesystem.a \
	-DBoost_INCLUDE_DIR:PATH=$PREFIX/include \
	-DBoost_LIBRARY_DIR_DEBUG:PATH=$PREFIX/lib \
	-DBoost_LIBRARY_DIR_RELEASE:PATH=$PREFIX/lib \
	-DBoost_PROGRAM_OPTIONS_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_program_options.a \
	-DBoost_PROGRAM_OPTIONS_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_program_options.a \
	-DBoost_REGEX_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_regex.a \
	-DBoost_REGEX_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_regex.a \
	-DBoost_SERIALIZATION_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_serialization.a \
	-DBoost_SERIALIZATION_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_serialization.a \
	-DBoost_SYSTEM_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_system.a \
	-DBoost_SYSTEM_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_system.a \
	-DBoost_THREAD_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_thread.a \
	-DBoost_THREAD_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_thread.a \
	-DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_DEBUG:FILEPATH=$PREFIX/lib/libboost_unit_test_framework.a \
	-DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_RELEASE:FILEPATH=$PREFIX/lib/libboost_unit_test_framework.a \
	  -DCMAKE_INSTALL_PREFIX=$PREFIX \
	  -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
	  -DCMAKE_PREFIX_PATH=$PREFIX \
	  -DENABLE_UHD=True -DENABLE_FCD=False -DENABLE_RFSPACE=False \
	  -DENABLE_BLADERF=False -DENABLE_HACKRF=False -DENABLE_OSMOSDR=False \
	  -DENABLE_RTL_TCP=False -DENABLE_IQBALANCE=False -DENABLE_RTL=ON\
	  -DBOOST_ROOT=$PREFIX -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
	  ../

echo ""; echo ""
echo "Building and installing OSMOSDR"
make -s -j${PARALLEL}
make -s install

cd ${TOP_BUILD_DIR}

############################################################
##                   GMP DEPENDENCY
############################################################

echo ""; echo ""; echo ""; echo ""

GMP_VER=6.1.0
GMP_DIR=gmp-${GMP_VER}
GMP_URL="https://gmplib.org/download/gmp/gmp-6.1.0.tar.xz"

if [ -e "${GMP_DIR}.tar.xz" ];
then
    echo "GMP file already downloaded; skipping"
else
    echo "Downloading GMP tarball"
    wget ${GMP_URL}
fi

if [ -d ${GMP_DIR} ];
then
    echo "GMP directory expanded; skipping"
else
    echo "Expanding GMP tarball"
    tar xJf ${GMP_DIR}.tar.xz
    chmod +r -R ${GMP_DIR}
fi

cd ${GMP_DIR}

mkdir -p build
cd build

export SYS_ROOT="$ANDROID_STANDALONE_TOOLCHAIN/sysroot"
export CC="clang --sysroot=$SYS_ROOT"
export LD="arm-linux-androideabi-ld"
export AR="arm-linux-androideabi-ar"
export RANLIB="arm-linux-androideabi-ranlib"
export STRIP="arm-linux-androideabi-strip"

echo ""; echo ""
echo "Configuring GMP"
../configure --host=arm-eabi --build=x86_64-linux \
  --prefix=$PREFIX \
  LIBS="-lc -lgcc -march=armv7-a -mfloat-abi=softfp -mfpu=neon" \
  CC="arm-linux-androideabi-gcc -march=armv7-a -mfloat-abi=softfp -mfpu=neon"

echo "\n\nBuilding and installing GMP"
make -s -j${PARALLEL}
make -s install

unset SYS_ROOT
unset CC
unset LD
unset AR
unset RANLIB
unset STRIP

cd ${TOP_BUILD_DIR}

############################################################
##                   NETTLE DEPENDENCY
############################################################

echo ""; echo ""; echo ""; echo ""

NETTLE_VER=3.1
NETTLE_DIR=nettle-${NETTLE_VER}
NETTLE_URL="https://ftp.gnu.org/gnu/nettle/nettle-3.1.tar.gz"

if [ -e "${NETTLE_DIR}.tar.gz" ];
then
    echo "NETTLE file already downloaded; skipping"
else
    echo "Downloading NETTLE tarball"
    wget ${NETTLE_URL}
fi

if [ -d ${NETTLE_DIR} ];
then
    echo "NETTLE directory expanded; skipping"
else
    echo "Expanding NETTLE tarball"
    tar xzf ${NETTLE_DIR}.tar.gz
    chmod +r -R ${NETTLE_DIR}
fi

cd ${NETTLE_DIR}


mkdir -p build
cd build

export SYS_ROOT="$ANDROID_STANDALONE_TOOLCHAIN/sysroot"
export CC="arm-linux-androideabi-gcc --sysroot=$SYS_ROOT"
export LD="arm-linux-androideabi-ld"
export AR="arm-linux-androideabi-ar"
export RANLIB="arm-linux-androideabi-ranlib"
export STRIP="arm-linux-androideabi-strip"

echo ""; echo ""
echo "Configuring NETTLE"
../configure --host=arm-eabi --build=x86_64-linux --enable-mini-gmp\
  --prefix=$PREFIX --disable-ld-version-script \
  LIBS="-lc -lgcc -march=armv7-a -mfloat-abi=softfp -mfpu=neon" \
  CC="clang -march=armv7-a -mfloat-abi=softfp -mfpu=neon"

#sed -i '257,262d' Makefile
#sed -i '262,267d' Makefile
echo "\n\nBuilding and installing NETTLE"
make -s -j${PARALLEL}
make -s install

#####
#build this twice to get rid of the soname
######
rm $PREFIX/lib/libnettle.so
rm $PREFIX/lib/libhogweed.so
rm libnettle.so
rm libhogweed.so

sed -i "s/-Wl,--version-script=libnettle.map//g" ../configure
sed -i "s/-Wl,--version-script=libhogweed.map//g" ../configure
sed -i "s/\$(LIBNETTLE_FORLINK).\$(LIBNETTLE_MAJOR)/\$(LIBNETTLE_FORLINK)/g" ../configure
sed -i "s/\$(LIBHOGWEED_FORLINK).\$(LIBHOGWEED_MAJOR)/\$(LIBHOGWEED_FORLINK)/g" ../configure

../configure --host=arm-eabi --build=x86_64-linux --enable-mini-gmp\
  --prefix=$PREFIX --disable-ld-version-script \
  LIBS="-lc -lgcc -march=armv7-a -mfloat-abi=softfp -mfpu=neon" \
  CC="clang -march=armv7-a -mfloat-abi=softfp -mfpu=neon"

#sed -i '257,262d' Makefile
#sed -i '262,267d' Makefile
echo "\n\nBuilding and installing NETTLE"
set -e
make -s -j${PARALLEL}
set +e

cp -a libnettle.so $PREFIX/lib/
cp -a libhogweed.so $PREFIX/lib/

unset SYS_ROOT
unset CC
unset LD
unset AR
unset RANLIB
unset STRIP

cd ${TOP_BUILD_DIR}


############################################################
##                   GNUTLS DEPENDENCY
############################################################

echo ""; echo ""; echo ""; echo ""

GNUTLS_VER=3.4.9
GNUTLS_DIR=gnutls-${GNUTLS_VER}
GNUTLS_URL="ftp://ftp.gnutls.org/gcrypt/gnutls/v3.4/gnutls-3.4.9.tar.xz"

if [ -e "${GNUTLS_DIR}.tar.xz" ];
then
    echo "GNUTLS file already downloaded; skipping"
else
    echo "Downloading GNUTLS tarball"
    wget ${GNUTLS_URL}
fi

if [ -d ${GNUTLS_DIR} ];
then
    echo "GNUTLS directory expanded; skipping"
else
    echo "Expanding GNUTLS tarball"
    tar xJf ${GNUTLS_DIR}.tar.xz
    chmod +r -R ${GNUTLS_DIR}
fi

cd ${GNUTLS_DIR}

mkdir -p build
cd build

export SYS_ROOT="$ANDROID_STANDALONE_TOOLCHAIN/sysroot"
export CC="clang --sysroot=$SYS_ROOT"
export LD="arm-linux-androideabi-ld"
export AR="arm-linux-androideabi-ar"
export RANLIB="arm-linux-androideabi-ranlib"
export STRIP="arm-linux-androideabi-strip"

#PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SYS_ROOT}

echo ""; echo ""
echo "Configuring GNUTLS"
../configure --host=arm-eabi --build=x86_64-linux \
  --prefix=$PREFIX --with-included-libtasn1 --without-p11-kit \
  --enable-openssl-compatibility --disable-ocsp \
  --disable-openpgp-authentication --disable-anon-authentication \
  --disable-psk-authentication --disable-srp-authentication \
  --disable-dtls-srtp-support  --enable-dhe --enable-ecdhe \
  --disable-doc --disable-tools \
  LIBS="-lc -lgcc -march=armv7-a -mfloat-abi=softfp -mfpu=neon" \
  CC="arm-linux-androideabi-gcc -march=armv7-a -mfloat-abi=softfp -mfpu=neon" \
  LDFLAGS=-L$PREFIX/lib \
  CFLAGS=-I$PREFIX/include

echo "\n\nBuilding and installing GNUTLS"
make -s -j${PARALLEL}
make -s install

unset SYS_ROOT
unset CC
unset LD
unset AR
unset RANLIB
unset STRIP

cd ${TOP_BUILD_DIR}

###########################################################
#          OPENBLAS DEPENDENCY
#########################################################

echo ""; echo ""; echo ""; echo ""

OPENBLAS_VER=0.2.18
OPENBLAS_DIR=OpenBLAS-${OPENBLAS_VER}
OPENBLAS_URL="http://github.com/xianyi/OpenBLAS/archive/v0.2.18.tar.gz"

if [ -e "v0.2.18.tar.gz" ];
then
    echo "OPENBLAS file already downloaded; skipping"
else
    echo "Downloading OPENBLAS tarball"
    wget ${OPENBLAS_URL}
fi

if [ -d ${OPENBLAS_DIR} ];
then
    echo "OPENBLAS directory expanded; skipping"
else
    echo "Expanding OPENBLAS tarball"
    tar xzf v0.2.18.tar.gz
#    mv OPENBLAS-3.2.1 clapack-3.2.1
    chmod +r -R ${OPENBLAS_DIR}
fi

cd ${OPENBLAS_DIR}


export SYS_ROOT="$ANDROID_STANDALONE_TOOLCHAIN/sysroot"
export CC="clang  --sysroot=$SYS_ROOT"
export LD="arm-linux-androideabi-ld"
export AR="arm-linux-androideabi-ar"
export RANLIB="arm-linux-androideabi-ranlib"
export STRIP="arm-linux-androideabi-strip"

#PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SYS_ROOT}

echo ""; echo ""

echo "\n\nBuilding and installing OPENBLAS"
#armv5 instead of v7 because of no softfp support
make TARGET=ARMV5 HOSTCC=gcc CC=clang NOFORTRAN=1 NO_LAPACK=1 -j${PARALLEL}
make PREFIX=${PREFIX} install


unset SYS_ROOT
unset CC
unset LD
unset AR
unset RANLIB
unset STRIP

cd ${TOP_BUILD_DIR}

############################################################
##                   CLAPACK DEPENDENCY
############################################################

echo ""; echo ""; echo ""; echo ""

CLAPACK_VER=3.2.1
CLAPACK_DIR=clapack
#CLAPACK_URL="http://www.netlib.org/clapack/clapack-3.2.1.tgz"

if [ -e "${CLAPACK_DIR}" ];
then
    echo "clapack file already cloned; skipping"
else
    echo "Git cloning clapack"
    git clone git://github.com/Hoernchen/clapack
fi

cd ${CLAPACK_DIR}


cp $PREFIX/lib/libopenblas_armv5p-r0.2.18.a blas_LINUX.a


#sed -i '23s/__off64_t/off64_t/'  F2CLIBS/libf2c/sysdep1.h0

export SYS_ROOT="$ANDROID_STANDALONE_TOOLCHAIN/sysroot"
export CC="clang --sysroot=$SYS_ROOT"
export LD="arm-linux-androideabi-ld"
export AR="arm-linux-androideabi-ar"
export RANLIB="arm-linux-androideabi-ranlib"
export STRIP="arm-linux-androideabi-strip"

#PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SYS_ROOT}
export PATH=${PATH}

echo ""; echo ""
echo "Configuring CLAPACK"

echo "\n\nBuilding and installing CLAPACK"
make f2clib -s -j${PARALLEL}
make lapacklib -s -j${PARALLEL}
make cblaswrap -s -j${PARALLEL}
#make -s install

##############################################
# http://stackoverflow.com/questions/3821916/how-to-merge-two-ar-static-libraries-into-one
# merge the archives to make linking easier
##### thin -a file which references the other two archives
#######arm-linux-androideabi-ar -rcT lapack_LINUX_wrap.a lapack_LINUX.a libcblaswr.a
arm-linux-androideabi-ar cqT tmp.a lapack_LINUX.a libcblaswr.a F2CLIBS/libf2c.a blas_LINUX.a && echo -e 'create lapack_LINUX_wrap.a\naddlib tmp.a\nsave\nend' | arm-linux-androideabi-ar -M
cp lapack_LINUX_wrap.a $PREFIX/lib/

unset SYS_ROOT
unset CC
unset LD
unset AR
unset RANLIB
unset STRIP

cd ${TOP_BUILD_DIR}

############################################################
##          ARMADILLO DEPENDENCY
############################################################

echo ""; echo ""; echo ""; echo ""


ARMADILLO_VER=6.700.6
ARMADILLO_DIR=armadillo-${ARMADILLO_VER}
ARMADILLO_URL="http://heanet.dl.sourceforge.net/project/arma/armadillo-6.700.6.tar.gz"

if [ -e "${ARMADILLO_DIR}.tar.gz" ];
then
    echo "ARMADILLO file already downloaded; skipping"
else
    echo "Downloading ARMADILLO tarball"
    wget ${ARMADILLO_URL}
fi

if [ -d ${ARMADILLO_DIR} ];
then
    echo "ARMADILLO directory expanded; skipping"
else
    echo "Expanding ARMADILLO tarball"
    tar xzf ${ARMADILLO_DIR}.tar.gz
    chmod +r -R ${ARMADILLO_DIR}
fi

cd ${ARMADILLO_DIR}
echo ""; echo ""
echo "Configuring ARMADILLO"
mkdir -p build
cd build
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SYS_ROOT}

cmake -Wno-dev \
	-DANDROID_NATIVE_API_LEVEL=21 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_static \
	-DLAPACK_LIBRARY=$PREFIX/lib/lapack_LINUX_wrap.a \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DBOOST_ROOT=$PREFIX -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
      ../

sed -i 's/CMAKE_C_COMPILER/clang/g' CMakeFiles/armadillo.dir/link.txt
echo ""; echo ""
echo "Building and installing ARMADILLO"
make -s -j${PARALLEL}
make -s install

cd ${TOP_BUILD_DIR}

############################################################
##          GFLAGS DEPENDENCY
############################################################

echo ""; echo ""; echo ""; echo ""


GFLAGS_VER=2.1.2
GFLAGS_DIR=gflags-${GFLAGS_VER}
GFLAGS_URL="https://github.com/gflags/gflags/archive/v2.1.2.tar.gz"

if [ -e "v2.1.2.tar.gz" ];
then
    echo "GFLAGS file already downloaded; skipping"
else
    echo "Downloading GFLAGS tarball"
    wget ${GFLAGS_URL}
fi

if [ -d ${GFLAGS_DIR} ];
then
    echo "GFLAGS directory expanded; skipping"
else
    echo "Expanding GFLAGS tarball"
    tar xzf v2.1.2.tar.gz
    chmod +r -R ${GFLAGS_DIR}
fi

cd ${GFLAGS_DIR}
echo ""; echo ""
echo "Configuring GFLAGS"
mkdir -p build
cd build
#PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PKG_CONFIG_DIR=
export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SYS_ROOT}

cmake -Wno-dev \
	-DBUILD_SHARED_LIBS=ON \
	-DANDROID_NATIVE_API_LEVEL=21 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DBOOST_ROOT=$PREFIX -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
      ../

echo ""; echo ""
echo "Building and installing GFLAGS"
make -s -j${PARALLEL}
make -s install


cd ${TOP_BUILD_DIR}

############################################################
##          GLOG DEPENDENCY
############################################################

echo ""; echo ""; echo ""; echo ""

GLOG_DIR=glog

if [ -e "${GLOG_DIR}" ];
then
    echo "GLOG file already cloned; skipping"
else
    echo "Git cloning GLOG"
    git clone https://github.com/Hoernchen/${GLOG_DIR}.git
fi

cd ${GLOG_DIR}

echo ""; echo ""
echo "Configuring GLOG"

#sed -i -e '457,545d' CMakeLists.txt

mkdir -p build
cd build
cmake -Wno-dev \
	-DBUILD_SHARED_LIBS=ON \
	-DANDROID_NATIVE_API_LEVEL=21 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DBOOST_ROOT=$PREFIX -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
      ../
	  
echo ""; echo ""
echo "Building and installing GLOG"
make -s -j${PARALLEL}
make -s install

cd ${TOP_BUILD_DIR}
###############################
###          GNSS-SDR-VOLK
###############################

echo ""; echo ""; echo ""; echo ""

GNSSSDR_DIR=gnss-sdr
#OSMOSDR_VER=android5

if [ -e "${GNSSSDR_DIR}" ];
then
    echo "gnss-sdr already cloned; skipping"
else
    echo "Git cloning gnss-sdr-volk"
    git clone git://github.com/Hoernchen/gnss-sdr
fi

cd ${GNSSSDR_DIR}/src/algorithms/libs/volk_gnsssdr_module/volk_gnsssdr/

#git checkout ${OSMOSDR_VER}

echo ""; echo ""
echo "Configuring gnss-sdr-volk"
mkdir -p build
cd build


###
# what the literal fuck. find /opt/android-ndk-r12b/ -type f -iname "*libm*" | xargs grep cargf | sort
# -> cargf is exported by the STATIC libm, but only available in the dynamically linked libm on api level > 22
# -> api level set to > 22
####
cmake -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release \
	-DANDROID_NATIVE_API_LEVEL=23 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
      -DGIT_EXECUTABLE=/usr/bin/git \
      -DENABLE_OSMOSDR=ON -DBOOST_ROOT=$PREFIX -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
      -DGLOG_INCLUDE_DIR=$PREFIX\include\glog -DGLOG_LIBRARIES=$PREFIX\lib\libglog.so \
      -DGLOG_ROOT=$PREFIX -DGFlags_ROOT_DIR=$PREFIX \
      -DPYTHON_EXECUTABLE=/usr/bin/python \
      ../

#sed -i 's/-lc++//g' apps/CMakeFiles/volk_gnsssdr_profile.dir/link.txt
#sed -i 's/-lc++//g' apps/CMakeFiles/volk_gnsssdr-config-info.dir/link.txt
echo ""; echo ""
echo "Building and installing gnss-sdr-volk"
make -s -j${PARALLEL} VERBOSE=1
make -s install

cd ${TOP_BUILD_DIR}
###############################
###          GNSS-SDR
###############################

echo ""; echo ""; echo ""; echo ""

GNSSSDR_DIR=gnss-sdr

if [ -e "${GNSSSDR_DIR}" ];
then
    echo "gnss-sdr file already cloned; skipping"
else
    echo "Git cloning gnss-sdr"
    git clone git://github.com/Hoernchen/gnss-sdr
#    sed -i 's/-lc++//g'  ${GNSSSDR_DIR}/src/tests/CMakeLists.txt
fi

cd ${GNSSSDR_DIR}
#git checkout ${OSMOSDR_VER}

echo ""; echo ""
echo "Configuring gnss-sdr"
mkdir -p build
cd build

#		-DCMAKE_BUILD_TYPE=Debug
cmake -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release \
	-DANDROID_NATIVE_API_LEVEL=23 \
	-DANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-clang \
	-DANDROID_STL=c++_shared \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DGIT_EXECUTABLE=/usr/bin/git \
      -DENABLE_OSMOSDR=ON -DBOOST_ROOT=$PREFIX -DPKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
      -DGLOG_INCLUDE_DIR=$PREFIX/include/glog -DGLOG_LIBRARIES=$PREFIX/lib/libglog.so \
      -DGLOG_ROOT=$PREFIX -DGFlags_ROOT_DIR=$PREFIX \
      -DGTEST_DIR=${ANDROID_NDK}/sources/third_party/googletest/googletest/ \
      ../

#dirty FIXME
#find . -name link.txt | xargs sed -i 's/-lc++//g'


echo ""; echo ""
echo "Building and installing gnss-sdr"
make -s -j${PARALLEL} V=1
make -s install
cp -a  src/tests/librun_tests.so $PREFIX/lib || true

cd ${TOP_BUILD_DIR}


