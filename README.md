Tool(s) for building GNU Radio GNSS-SDR for Android.

This script will build the Android version of GNSS-SDR, this requires approx. 7GB of free space and will take some time (~1h).
Calling the script should look like this:
~~~~~~ 
PREFIX=/gnss/test5/install PARALLEL=4 ANDROID_NATIVE_API_LEVEL=21 ANDROID_SDK=/opt/android-sdk ANDROID_NDK=/opt/android-ndk-r11c  ./gnsssdr-build.sh
~~~~~~ 

The resulting binaries can be deployed by pushing the gnss-sdr binary + all *.so files from install/lib to the android device.
Since this work is far from done the only way to run gnss-sdr on the phone is using the shell, i.e.:
~~~~~~ 
TMP=/data/local/tmp LD_LIBRARY_PATH=/path/to/pushed/libs ./gnss-sdr --config_file=gnss-sdr_Galileo_E1_ishort.conf
~~~~~~ 
Setting the TMP environment variable is important!


For more details, see the GNU Radio [Android Page](http://gnuradio.org/redmine/projects/gnuradio/wiki/Android) or specifically the [Instructions to build the dependencies](http://gnuradio.org/redmine/projects/gnuradio/wiki/GRAndDeps) as well as [Instructions to build GNU Radio](http://gnuradio.org/redmine/projects/gnuradio/wiki/GRAndBuild).

It is tested with Ubuntu 16.04, 64-bit. There are likely a handful of apt-gettable programs necessary for this to complete. You will definitely need the following:
- cmake
- git
- make
- xutils-dev
- automake
- autoconf
- libtool
- wget
- perl
- tar
- sed
