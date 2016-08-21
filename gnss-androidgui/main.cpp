#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickView>
#include <QQmlContext>
#include "appinterface.h"

static AppInterface* global_app = 0;

//######## weak ref glog:logger.cc
//######## needs appinterface
void android_log_hook ( const char * msg, size_t size){
    //std::lock_guard<std::mutex> lock(m);
    size = size > 4095 ? 4095 : size;
    static char buf[4096];
    memcpy(buf, msg, size);
    buf[size] = 0;

    global_app->external_addLogLine(buf);
}


int main(int argc, char *argv[])
{
    QGuiApplication a(argc, argv);

    //QQuickView *view = new QQuickView();
    //QQmlApplicationEngine engine;
    QQuickView view;
    AppInterface* itf = new AppInterface();
    global_app = itf;

    qRegisterMetaType<GnssLogListModel *>("SimpleListModel");




//    view->setResizeMode(QQuickView::SizeRootObjectToView);
//    view->rootContext()->setContextProperty("_intname", m_GLSpectrum);
//    view->rootContext()->setContextProperty(QLatin1String("sdrcontrol"), m_sdrcontrol);
//    view->setSource(QUrl("qrc:/main.qml"));
view.setMinimumSize(QSize(720, 1280));
//    view->showFullScreen();


    view.rootContext()->setContextProperty("AppInterface", itf);
    view.setSource(QUrl(QStringLiteral("qrc:/main.qml")));
    view.show();

    return a.exec();
}


/*
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFuture>
#include <QtConcurrent/QtConcurrent>

#include <glog/logging.h>
#include <cstdio>
#include <iostream>
#include <mutex>


FILE * pFile;
std::mutex m;

static QQmlApplicationEngine* engine2;
QStringList dataList;

extern int gnssdr_test_main(int argc, char **argv);
static int printmod=0;

void android_log_hook ( const char * msg, size_t size){
    //std::lock_guard<std::mutex> lock(m);
    static char buf[4096];
    memcpy(buf, msg, size);
    buf[size] = 0;

    fprintf(pFile, buf);
    fflush(pFile);
    //std::cout << buf;
    //return size;
   // dataList.append(QString(buf));
    //printmod +=1;
    //if(printmod % 64)
    //engine2->rootContext()->setContextProperty("myModel", QVariant::fromValue(dataList));
}



int main(int argc, char *argv[])
{
    FLAGS_logtostderr = 1;
    QApplication app(argc, argv);

    pFile = fopen ("dump.txt","w");


       dataList.append("Item 1");
       dataList.append("Item 2");
       dataList.append("Item 3");
       dataList.append("Item 4");


    QQmlApplicationEngine engine;
    engine2 = &engine;

    engine.rootContext()->setContextProperty("myModel", QVariant::fromValue(dataList));

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));


    char* arguments[3];
    arguments[0] = "foo"; // i'm a lib...
    arguments[1] = "-logtostderr";
    arguments[2] = "-minloglevel=2";// only capture error output which used to be std::cout
    char** args = arguments;

    QFuture<void> future = QtConcurrent::run(gnssdr_test_main, 3, args);

    return app.exec();
    fclose (pFile);
}


 * */
