TEMPLATE = app

QT += qml quick widgets


# either gnss_app or gnss_test
# WARNING: changing this requires a manual rebuild!
CONFIG += c++11 gnss_app
PATH_TO_ANDROID_BUILD = $$PWD/../../midterm/install


SOURCES += main.cpp \
    appinterface.cpp \
    libusbhelper.c \
    gnssloglistmodel.cpp


HEADERS += \
    appinterface.h \
    log.h \
    gnssloglistmodel.h


RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
#include(deployment.pri)

gnss_app {
    #LIBS += -L$$PWD/../gnss-sdr/build/src/main/ -lgnss-sdr
    LIBS += -L$${PATH_TO_ANDROID_BUILD}/ -lgnss-sdr
    DEFINES += BUILD_THE_APP
    ANDROID_EXTRA_LIBS += $${PATH_TO_ANDROID_BUILD}/lib/libgnss-sdr.so
}
gnss_test {
    #LIBS += -L$$PWD/../gnss-sdr/build/src/tests/ -lrun_tests
    LIBS += -L$${PATH_TO_ANDROID_BUILD}/ -lrun_tests
    DEFINES += BUILD_THE_TESTS
    ANDROID_EXTRA_LIBS += $${PATH_TO_ANDROID_BUILD}/lib/librun_tests.so
}

#LIBS += -L/home/epsilon/grkram/bombroot/lib/
LIBS += -L$${PATH_TO_ANDROID_BUILD}/lib


LIBS +=  -lusb1.0 -lgnuradio-analog -lgnuradio-blocks -lgnuradio-channels -lgnuradio-digital \
-lgnuradio-fec -lgnuradio-fft -lgnuradio-filter -lgnuradio-osmosdr  -lgnuradio-pmt \
-lgnuradio-runtime -lgnuradio-trellis -lgnuradio-uhd

INCLUDEPATH += $${PATH_TO_ANDROID_BUILD}/include


ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
ANDROID_EXTRA_LIBS += \
$${PATH_TO_ANDROID_BUILD}/lib/libc++_shared.so \
$${PATH_TO_ANDROID_BUILD}/lib/libusb1.0.so \
$${PATH_TO_ANDROID_BUILD}/lib/libc++.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgflags_nothreads.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgflags.so \
$${PATH_TO_ANDROID_BUILD}/lib/libglog.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-analog.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-blocks.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-channels.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-digital.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-fec.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-fft.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-filter.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-grand.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-osmosdr.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-pmt.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-runtime.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-trellis.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-uhd.so \
$${PATH_TO_ANDROID_BUILD}/lib/libgnuradio-zeromq.so \
$${PATH_TO_ANDROID_BUILD}/lib/libhogweed.so \
$${PATH_TO_ANDROID_BUILD}/lib/libm.so \
$${PATH_TO_ANDROID_BUILD}/lib/libnettle.so \
$${PATH_TO_ANDROID_BUILD}/lib/libarmadillo.so \
$${PATH_TO_ANDROID_BUILD}/lib/librtlsdr.so \
$${PATH_TO_ANDROID_BUILD}/lib/librun_tests.so \
$${PATH_TO_ANDROID_BUILD}/lib/libuhd.so \
$${PATH_TO_ANDROID_BUILD}/lib/libvolk_gnsssdr.so \
$${PATH_TO_ANDROID_BUILD}/lib/libvolk.so


OTHER_FILES += \
    android/AndroidManifest.xml



DISTFILES += \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew \
    android/gradlew.bat \
    android/src/gnsssdr/android/GnssActivity.java
