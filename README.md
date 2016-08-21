# Tool(s) for building GNU Radio GNSS-SDR for Android.

List of changes and other repos used by the build script (excluding minor fixes by the build scripts)
* https://github.com/Hoernchen/qtbase/commits/dev?author=Hoernchen
* https://github.com/Hoernchen/glog/commits/master?author=Hoernchen
* https://github.com/Hoernchen/gr-grand/commits/master?author=Hoernchen
* https://github.com/Hoernchen/clapack/commits/master?author=Hoernchen
* https://github.com/Hoernchen/rtl-sdr/commits/master?author=Hoernchen
* https://github.com/Hoernchen/volk/commits/android?author=Hoernchen
* https://github.com/Hoernchen/libusb-android/commits/v1.0.19-and5?author=Hoernchen
* https://github.com/Hoernchen/gnss-sdr/commits/master?author=Hoernchen
* https://github.com/Hoernchen/gr-osmosdr/commits/android5?author=Hoernchen
* https://github.com/Hoernchen/uhd/commits/android?author=Hoernchen

Requirements:
Android NDK, SDK,  Qt Creator, the usual build tools

Currently working:
* Android build with clang + libc++, proper neon support, everything including gnss-sdr gets built as shared libraries
* GUI can be used on a desktop linux when combined with modified gnss-sdr and glog
* ..although this is somewhat pointless, since the gui has very little to offer
Not working:
* Android gui
* rtklib integration

The script will build the Android version of GNSS-SDR, this requires approx. 7GB of free space and will take some time (~1h).
Calling the script should look like this:
~~~~~~ 
PREFIX=/gnss/test5/install PARALLEL=4 ANDROID_NATIVE_API_LEVEL=21 ANDROID_SDK=/opt/android-sdk ANDROID_NDK=/opt/android-ndk-r12b  ./gnsssdr-build.sh
~~~~~~ 

The $PREFIX/lib folder will then contain all built libs which can be used on Android.


The resulting binaries can be deployed by pushing the gnss-sdr binary + all *.so files from install/lib to the android device.
It is also possible to build proper binaries that can be run using using the shell, this requires undoing the "libification" patch.
The proper way to run these binaries looks like this:
~~~~~~ 
TMP=/data/local/tmp LD_LIBRARY_PATH=/path/to/pushed/libs ./gnss-sdr --config_file=gnss-sdr_Galileo_E1_ishort.conf
~~~~~~ 
Setting the TMP environment variable is mandatory for the gnuradio circbuf factory!
All binaries should work, volk_gnsssdr_profile will probably crash deep inside a throw, in boost. This look like the compiler or libc++ is at fault.


## The why & what & how

The android sdk suffers from all kind of issues, i.e. [1], so building with g++ and libstdc++ is not possible. It can be fixed to some extent, at which point it willl compile, but the resulting binaries will crash.
The crystax NDK has its own share of issues, i.e. [2][3], but the resulting binaries will crash as well.
This leads to the only possible alternative: building with clang and libc++, which provides proper c++11 support and produces working binaries.
Of course there is a downside to this: qt does not currently support building for android with clang and libc++, this will probably change soon because gcc is deprecated [4].

It is very important to make sure that there is no libstdc++ linked in as well, mixing runtimes causes crashes.
The easiest way to do this is

~~~~~~ 
readelf -d *so | grep -E '^File|NEEDED'
~~~~~~ 



Building qt5 works like this:
~~~~~~ 
git clone git://code.qt.io/qt/qt5.git
cd qt5
perl init-repository
rm -rf ./qtbase
git clone https://github.com/Hoernchen/qtbase.git
./configure -debug -no-pch -opensource -confirm-license -xplatform android-clang -nomake tools -nomake tests -nomake examples -android-ndk /opt/android-ndk-r12b -android-sdk /opt/android-sdk -android-ndk-host linux-x86_64 -android-toolchain-version 4.9 -skip qttranslations -skip qtwebkit -skip qtserialport -skip qtwebkit-examples -skip qtconnectivity -skip qtwebkit -skip qtmultimedia -skip qt3d -skip qtenginio -skip qtwebsockets -skip qtwebview -skip qtquick1 -skip qtgamepad -skip qtscript -skip qtcharts -skip qtpurchasing -skip qtscxml -skip qtwebchannel -skip qtdatavis3d -no-warnings-are-errors -prefix /opt/qt-android -android-ndk-platform android-21 && make
~~~~~~ 
Mind the paths to the sdk and ndk. Some parts (qttools) might require headers from the ndk not present in the used api levels, the easiest fix is to copy those headers from other api levels. If the build breaks try to checkout out the dev branches, some submodules are somewhat unstable.
Refer to the qt documentation to set up this new qt version as a kit so it can be used to build the gui app for Android, it might be neccessary to manually set the mkspec to "android-clang".

Unfortuantely this qt version will then suffer from all kinds of subtile bugs, i.e. the map element which could be used to plot the positions currently looks like this:
![nope](https://raw.githubusercontent.com/Hoernchen/grand-build/master/broken-map.jpg "broken map")

Building a release version of qt will break it completely, so this is likely some sort of compiler/libc++ bug that will most likely get fixed as soon as libc++ is supported.

Integrating RTKLIB was not possible due to the fact that neither rtknavi nor rtkrcv would use the satellites when connected to the rtcm server of gnss-sdr, even though gnss-sdr kept printing position fixes.

The neon kernels used by volk and gnsssdr_volk work out of the box, although the performance impact is almost negligible.

OpenBLAS is currently using the neon kernels, due to the fact that hardfloat on android is deprecated. A softfp version of OpenBLAS is unable to use the neon assembly kernels, because the ABI is different.
A possible way to fix this would be to do the opposite of what google has been doing: decorate the function declarations with __attribute__((pcs("aapcs-vfp"))) to override the ABI for those functions. This leads to binary that is marked as hardfp with proper calls to those functions, while actually being compatible with other softfp binaries as long as the attribute is visible for all calling functions. The downside to this approach is that linker needs the --no-warn-mismatch flag. Since the BLAS/LAPACK use in gnss-sdr is mostly constrained to PVT the performance impact of this optimization would be negligible compared to the actual signal processing, and was therefore not implemented.

Libusb on Android is still somewhat cumbersome, because the application requires permission to open a usb device (or just look at what's in /dev/bus/usb) first, and file descriptors have to be obtained by using the Java API. The tightening of the selinux permissions (no netlink) in android 5.0 made additional changes to libusb necessary - the removal of the netlink part.
When launching the Application by plugging in the USB device after making the VID/PID known using the manifest the application will implicitly be granted access rights to the device. This is also true if the application is already running, and the user chooses to "launch" it again after plugging in the device, as long as the launchMode is set to singleInstance in the manifest. The only remianing issue is a clumsy user who decided to start the app, and denies the permissions.
The easiest way to make sure that the required usb permissions were granted to the application before trying to use the usb device is to split this problem into two parts: libusb itself can handle getting a file descriptor for the usb device by using some jni magic, while the GUI makes sure that nothing tries to access the usb device without having been granted the necessary permissions first by listening to all usb connect/disconnect notifications. This approach has the advantage that it requires no modifications to all the parts of the software above libusb and below the gui, and is therefore preferable to the approach taken by the existing gnuradio-android port, which requires additional modifications to code using libusb.
For the sake of completenes it should be noted that there do exist other somewhat funky approaches to getting the FD without using the java API, i.e. by searching /proc/self/fd/ [5], it is also possible to pass the fd to other processes by using the Android binder. The biggest issue with binder is that it is not exposed to the NDK, so unless the application uses internal Android headers the only way to use Binder is JNI.


Redirecting the output of gnss-sdr turned out to be a bit of an issue, the glog framwork does not offer capturing the output out of the box (only to stderr or a file, neither is useful in a gui app) so this required adding a hook to glog to be able to access the output. Unfortunately gnss-sdr relies on quite a few direct writes to std::cout, which can't be redirected easily, this was solved by replacing those outputs with writes to LOG(ERROR) and filtering the glog output by setting minloglevel to ERROR ( = 3) to be able to capture the "standard" output. Future work in this area could involve adding a central logging class that captures the gnss-sdr output and decides whether to output it to stdout/stderr and makes it availavble to gui apps which might need it. The c runtime on linux has fopencookie for cases like this, which is not part of the POSIX standard, and it is missing from Android's bionic as well. A working implementation for Android is available on Github [6], apparently extracted from the Tesseract OCR Android port.

The easiest way to interact with a GUI without having to rewrite large parts of existing console applications is to use weak functions imported from the gui as callbacks, this is being used to interact with glog and stop the gnss-sdr flowgraph. A better way would be not to modify gnss-sdr at all, connect th rtcm output to RTKLIB, and only interact with RTKLIB.

### Things left to do
* Wait until the qt framework supports clang + libc++
* Use the (now working) QML map component provided by QT to display positions
* Investigate why the rtcm output is not used by RTKLIB
* Figure out why the App crashes on Android after initializing UHD





[1] https://code.google.com/p/android/issues/detail?id=54418
[2] https://groups.google.com/forum/#!topic/crystax-ndk/W84bE09LtiU
[3] https://github.com/crystax/android-platform-bionic/commit/9041d6a287d202c78b7bb888da2e4c93b44ee19e
[4] https://android.googlesource.com/platform/ndk.git/+/master/CHANGELOG.md
[5] https://github.com/Gritzman/libusb.git
[6] https://github.com/j-jorge/android-stdioext
