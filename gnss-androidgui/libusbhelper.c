#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

#include "log.h"

static struct logger log = {
    .name = "libusbhelper",
    .log_level = LEVEL_TRACE,
    .log_func = default_log,
};


#include <jni.h>
#include <fcntl.h>
extern void usb_device_set_open_close_func(void* openf, void* closef);

#define MAX_OPEN  10
//static JNIEnv *env;
JavaVM *gJavaVm = NULL;
static jobject launcherActivity = NULL;
//static jclass launcherClass = NULL;
static jclass helperclass = NULL;

struct fdlist {
    int fd;
    int is_native;
    jobject connection;
};

static struct  fdlist fd_list[MAX_OPEN] = {
{ .fd = -1, 0 , .connection = NULL, },
{ .fd = -1, 0 , .connection = NULL, },
{ .fd = -1, 0 , .connection = NULL, },
{ .fd = -1, 0 , .connection = NULL, },
{ .fd = -1, 0 , .connection = NULL, },
{ .fd = -1, 0 , .connection = NULL, },
{ .fd = -1, 0 , .connection = NULL, },
{ .fd = -1, 0 , .connection = NULL, },
{ .fd = -1, 0 , .connection = NULL, },
{ .fd = -1, 0 , .connection = NULL, },
};


static jfieldID field_context;

static struct usb_device* get_device_from_object(JNIEnv* env, jobject connection)
{

    return (struct usb_device*)(*env)->GetIntField(env, connection, field_context);
}
/*

 -> java open -> getfd

*/
static int android_java_usbdevice_open(const char *pathname, int mode, ...)
{
    JNIEnv* env = NULL;
    jint retval = 0;
    int i;
    int detach = 0;

    if (strncmp(pathname,"/sys",4) == 0 ) {
        retval  = open(pathname,mode);
        for (i =0 ; i < MAX_OPEN ; i++){ /* pick the first free slot */
            if (fd_list[i].fd == -1){
                fd_list[i].fd = retval;
                fd_list[i].is_native =1;
                fd_list[i].connection = NULL;
                break;
            }
        }
        if (i == MAX_OPEN){
            log_debug(&log,"MAX_OPEN REACHED\n");
            return -1;
        }
        return retval;
    }

    if( (*gJavaVm)->GetEnv(gJavaVm, (void **)&env, JNI_VERSION_1_6) != JNI_OK){
        (*gJavaVm)->AttachCurrentThread(gJavaVm, &env, NULL);
        detach=1;
    }

    //jclass helperclass = (*env)->FindClass(env, "rtlsdr/android/RtlSdrUsbHelper");
    //jmethodID helperconstructor = (*env)->GetMethodID(env, helperclass, "<init>", "()V");
    //jobject helperobj = (*env)->NewObject(env, helperclass, helperconstructor);
    //(*env)->CallVoidMethod(env, helperobj, (*env)->GetMethodID(env, helperclass, "initstuff", "()V"));

    log_debug(&log,"OPEN  %s, %d\n",pathname,mode);
    jclass cls = (*env)->GetObjectClass(env, launcherActivity);
    jmethodID mid = (*env)->GetMethodID(env, cls, "open", "(Ljava/lang/String;)Landroid/hardware/usb/UsbDeviceConnection;");
    if (mid == 0){
        retval = -1;
        goto out;
       }

    jstring text = (*env)->NewStringUTF(env, pathname);
    jobject o  = (*env)->CallObjectMethod(env, launcherActivity, mid, text);
    if (o == NULL){
        retval = -1;
        goto out;
    }

    jobject conn = (*env)->NewGlobalRef(env, o);
    if ( conn == NULL){
        log_debug(&log, "usb device connection == null\n");
        retval = -1;
        goto out;
    }

    jclass connectionClass =  (*env)->GetObjectClass(env, o);
    if (  connectionClass == NULL){
        log_debug(&log,"Connection class === null\n");
        retval = -1;
        goto out;
    }
    mid = (*env)->GetMethodID(env, connectionClass, "getFileDescriptor", "()I");
    if (mid == 0){
        log_debug(&log,"Mid  == 0\n");
        retval = -1;
        goto out;
    }
    retval   = (*env)->CallIntMethod(env, conn, mid);
    if (retval < 0){
        log_debug(&log,"hanlde(%d) is invalid\n",retval);
    }
    retval = dup(retval);
    if (retval < 0){
        log_debug(&log,"dup hanlde(%d) is invalid\n",retval);
    }
    for (i =0 ; i < MAX_OPEN ; i++){ /* pick the first free slot */
        if (fd_list[i].fd == -1){
            fd_list[i].fd = retval;
            fd_list[i].is_native = 0;
            fd_list[i].connection = conn;
            break;
        }
    }
    if (i == MAX_OPEN){
        log_debug(&log,"MAX_OPEN REACHED\n");
        retval = -1;
        goto out;
    }

out:
    if(detach)
        (*gJavaVm)->DetachCurrentThread(gJavaVm);

    //(*env)->CallVoidMethod(env, launcherActivity, (*env)->GetMethodID(env, helperclass, "killme", "()V"));

    log_debug(&log,"android_java_usbdevice_open  %d\n", retval);
    return retval;
}

static int android_java_usbdevice_close(int fd)
{
    JNIEnv* env = NULL;
    jint retval = 0;
    int i;
    int detach = 0;

    if( (*gJavaVm)->GetEnv(gJavaVm, (void **)&env, JNI_VERSION_1_6) != JNI_OK){
        (*gJavaVm)->AttachCurrentThread(gJavaVm, &env, NULL);
        detach=1;
    }

    log_debug(&log,"android_java_usbdevice_close  %d\n", fd);

    for(i= 0; i < MAX_OPEN; i++){
        if (fd_list[i].fd == fd){
            if (fd_list[i].is_native){
                close(fd);
                fd_list[i].fd = -1;
                fd_list[i].is_native = 0;
                fd_list[i].connection = NULL;
                retval = 0;
                goto out;
            } else {
                /* call java close */
                jclass connectionClass =  (*env)->GetObjectClass(env, fd_list[i].connection);
                if (  connectionClass == NULL){
                    log_debug(&log,"Connection class === null\n");
                    retval = -1;
                    goto out;
                }
                jmethodID mid = (*env)->GetMethodID(env, connectionClass, "close", "()V");
                if (mid == 0){
                    log_debug(&log,"Mid  == 0\n");
                    retval = -1;
                    goto out;
                }
                (*env)->CallVoidMethod(env, fd_list[i].connection , mid);
                fd_list[i].fd = -1;
                (*env)->DeleteGlobalRef(env, fd_list[i].connection);
                fd_list[i].connection = NULL;
                retval = 0;
                goto out;
            }
        }
    }
    log_debug(&log,"Close was called with fh %d but no handle was found\n",fd);
    retval = -1;

out:
    if(detach)
        (*gJavaVm)->DetachCurrentThread(gJavaVm);
    return retval;
}

void init_libusbhelper(JNIEnv *envp, jobject objp)
{
    launcherActivity = (*envp)->NewGlobalRef(envp, objp);
    usb_device_set_open_close_func(android_java_usbdevice_open, android_java_usbdevice_close);
}

void getGlobalRef(JNIEnv* jenv, const char* clazz, jclass* globalClass)
{
  jclass local = (*jenv)->FindClass(jenv,clazz);
  log_debug(&log,"FindClass  %d\n",local);
  if (local)
  {
     *globalClass = (jclass) (*jenv)->NewGlobalRef(jenv,local);
      log_debug(&log,"NewGlobalRef  %d\n",*globalClass);
     (*jenv)->DeleteLocalRef(jenv,local);
  } else
  log_debug(&log,"oh well, let's try the another class..\n");
}


JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *javaVm, void *reserved) {
    JNIEnv* localenv = NULL;
    gJavaVm = javaVm;
    (*gJavaVm)->GetEnv(gJavaVm, (void **)& localenv, JNI_VERSION_1_6);
    getGlobalRef(localenv, "rtlsdr/android/SdrangeActivity", &helperclass);
    //if ((*localenv)->ExceptionCheck(localenv)) {
//      (*localenv)->ExceptionClear(localenv);
//        getGlobalRef(localenv, "rtlsdr/android/MainActivity", &helperclass);
//    }
//    //launcherClass = (*localenv)->FindClass(localenv, "rtlsdr/android/MainActivity");
//    usb_device_set_open_close_func(android_java_usbdevice_open, android_java_usbdevice_close);
    return JNI_VERSION_1_6;
}

JNIEXPORT jint JNICALL Java_rtlsdr_android_SdrangeActivity_nativeGiefObject(JNIEnv *envp, jobject objp)
{
    init_libusbhelper(envp,objp);
    return 0;
}

JNIEXPORT void JNICALL Java_rtlsdr_android_SdrangeActivity_nativeSetTMP(JNIEnv* envp, jobject objp, jstring tmpname)
{
  const char *tmp_c;
  tmp_c = (*envp)->GetStringUTFChars(envp, tmpname, NULL);
  setenv("TMP", tmp_c, 1);
}


extern unsigned int android_devicecount;
//careful here: static in java -> jclass instead of jobj
JNIEXPORT void JNICALL Java_rtlsdr_android_SdrangeActivity_nativeusbAtt(JNIEnv *envp, jclass cls, jint ji)
{
    android_devicecount += 1;
    return;
}
JNIEXPORT void JNICALL Java_rtlsdr_android_SdrangeActivity_nativeusbDis(JNIEnv *envp, jclass cls, jint ji)
{
    android_devicecount -= 1;
    return;
}
