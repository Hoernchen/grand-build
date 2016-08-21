package gnsssdr.android;

import android.app.Notification;
import android.app.NotificationManager;
import android.content.Context;
import android.os.Bundle;


import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbManager;
import android.util.Log;
import android.os.HandlerThread;
import android.os.Looper;
import android.os.Handler;
import android.view.WindowManager.LayoutParams;

import java.util.List;
import java.util.ArrayList;

public class GnssActivity extends org.qtproject.qt5.android.bindings.QtActivity
{
    private static GnssActivity m_instance;

    private final String TAG = "UsbHelper";
    private static UsbManager m_UsbManager;
    public PendingIntent mPermissionIntent;
    private final String ACTION_USB_PERMISSION = "com.android.example.USB_PERMISSION";
    private List<Integer> m_devMap;
    private boolean isReceiverRegistered;

    //jni interface
    // careful: jni side for non-static calls receives an object as 2nd param,
    // for static calls it gets the class!
    private native int nativeGiefObject();
    private static native void nativeusbAtt(int id);
    private static native void nativeusbDis(int id);
    public native void nativeSetTMP(String tmpname);


    public GnssActivity()
    {
        m_instance = this;
        m_devMap = new ArrayList<Integer>();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        Log.i(TAG, "onCreate !");
            super.onCreate(savedInstanceState);

            // TMP path for gnuradio circbuf factory, jni call
            nativeSetTMP(getCacheDir().getAbsolutePath());

            m_UsbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
            mPermissionIntent = PendingIntent.getBroadcast(this, 0, new Intent(ACTION_USB_PERMISSION), 0);


            HandlerThread handlerThread = new HandlerThread("ht");
            handlerThread.start();
            Looper looper = handlerThread.getLooper();
            Handler handler = new Handler(looper);

            registerReceiver(mPermReceiver, new IntentFilter(ACTION_USB_PERMISSION), null, handler);
            registerReceiver(mPermReceiver, new IntentFilter(UsbManager.ACTION_USB_DEVICE_ATTACHED), null, handler);
            registerReceiver(mPermReceiver, new IntentFilter(UsbManager.ACTION_USB_DEVICE_DETACHED), null, handler);
            isReceiverRegistered = true;

            int fooo = nativeGiefObject(); // hand over this activity -> libusb

            //a better "wakelock"
            getWindow().addFlags(LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    public UsbDeviceConnection open(String device_name) {
        Log.d(TAG, "Open called " + device_name);
        UsbDevice usbDevice;
        usbDevice = m_UsbManager.getDeviceList().get(device_name);
        if (usbDevice != null) {
                return m_UsbManager.openDevice(usbDevice);
            }
        return null;
    }

    private final BroadcastReceiver mPermReceiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            if (ACTION_USB_PERMISSION.equals(action)) {
                synchronized (this) {
                    final UsbDevice device = (UsbDevice)intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        if(device != null)
                        {
                            m_devMap.add(device.getProductId());
                            nativeusbAtt(device.getProductId());
                        }
                    }
                    else {
                        Log.d(TAG, "wtf not granted...");
                    }
                }
            }
            if (UsbManager.ACTION_USB_DEVICE_ATTACHED.equals(action))
            {
                synchronized(this)
                {
                    UsbDevice device = (UsbDevice)intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    if (device != null)
                    {
                        m_UsbManager.requestPermission(device, mPermissionIntent);
                    }
                }
            }
            if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(action))
            {
                synchronized(this)
                {
                    UsbDevice device = (UsbDevice)intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    nativeusbDis(device.getProductId());
                    m_devMap.remove(Integer.valueOf(device.getProductId()));
                }
            }

        }
    };

    @Override
    public void onDestroy() {
        Log.i(TAG, "onDestroy !");
        try {
            unregisterReceiver(mPermReceiver);
        } catch (IllegalArgumentException e) {}
            isReceiverRegistered = false;
        super.onDestroy();
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (isReceiverRegistered) {
            try {
                unregisterReceiver(mPermReceiver);
            } catch (IllegalArgumentException e) {}
            isReceiverRegistered = false;
        }
    }
    @Override
    protected void onResume() {
        super.onResume();
        if (!isReceiverRegistered) {
            registerReceiver(mPermReceiver, new IntentFilter(ACTION_USB_PERMISSION));
            registerReceiver(mPermReceiver, new IntentFilter(UsbManager.ACTION_USB_DEVICE_ATTACHED));
            registerReceiver(mPermReceiver, new IntentFilter(UsbManager.ACTION_USB_DEVICE_DETACHED));
            isReceiverRegistered = true;
        }
    }


    @Override
    protected void onNewIntent(Intent intent) {
        Log.i(TAG, "onNewIntent !");
        super.onNewIntent(intent);
    }

    /*
    https://stackoverflow.com/questions/6981736/android-3-1-usb-host-broadcastreceiver-does-not-receive-usb-device-attached

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        if (UsbManager.ACTION_USB_ACCESSORY_ATTACHED.equals(intent.getAction())) {
            LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
        }
    }
     */
}
