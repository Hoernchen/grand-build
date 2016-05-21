Tool(s) for building GNU Radio GNSS-SDR for Android.

This script is currently only going to build gnuradio + dependencies of gnss-sdr using the Android toolchain.

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
