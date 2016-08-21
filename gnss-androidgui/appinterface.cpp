#include <thread>
#include <QFuture>
#include <QtConcurrent/QtConcurrent>
#include <QThread>
#include "appinterface.h"

#ifdef BUILD_THE_TESTS
extern int gnssdr_test_main(int argc, char **argv);
#endif
#ifdef BUILD_THE_APP
extern int gnsssdr_app_main(int argc, char** argv);
#endif

#define CPYARG(x,n)      int sz##n = strlen("#x"); \
arguments[n] = new char[sz##n]; \
memcpy(arguments[n], "##x", sz##n);


volatile bool thread_should_exit=false;

//#### weak ref in gnss-sdr:control_thread.cc
bool android_exit_hook(){
    qDebug() << "in cb";
    if(thread_should_exit)
        return true;
    return false;
}

extern "C" {
unsigned int android_devicecount;
}

//#########################################

static QString logpath;
static QString confpath;

class WorkerThread_test : public QThread {
    void run() {
        char logp[512] = "--log_dir=";
        char confp[512] = "--config_file=";
        strcat(logp, logpath.toStdString().c_str());
        strcat(confp, confpath.toStdString().c_str());

        const char* arguments[5];
        arguments[0] = "foo";
        arguments[1] = "-logtostderr";
        arguments[2] = "-minloglevel=2";// only capture error output which used to be std::cout

        arguments[3] = logp;
        arguments[4] = confp;
        #ifdef BUILD_THE_TESTS
        gnssdr_test_main(5, (char**)arguments);
        #endif
    }
};

class WorkerThread_app : public QThread {
    void run() {
        char logp[512] = "--log_dir=";
        char confp[512] = "--config_file=";
        strcat(logp, logpath.toStdString().c_str());
        strcat(confp, confpath.toStdString().c_str());

        const char* arguments[5];
        arguments[0] = "foo";
        arguments[1] = "-logtostderr";
        arguments[2] = "-minloglevel=2";// only capture error output which used to be std::cout

        arguments[3] = logp;
        arguments[4] = confp;
        #ifdef BUILD_THE_APP
        gnsssdr_app_main(5, (char**)arguments);
        #endif
    }
};


AppInterface::AppInterface(QObject *parent) :
    QObject(parent)
{
    m_SimpleListModel = new GnssLogListModel(this);

    // we're currently not in the gui thread, so re-submit this to the gui eventloop
    connect(this, &AppInterface::add, this, &AppInterface::internal_addLogLine, Qt::QueuedConnection);

    QTimer* timer = new QTimer(this);
    QObject::connect(timer, &QTimer::timeout, [this](){
        qDebug() << "devcount :" << android_devicecount;
        emit deviceCountChanged(android_devicecount);
    });
    connect(timer, &QTimer::timeout, timer, &QTimer::deleteLater);
    timer->setSingleShot(false);
    timer->start(500);
}

GnssLogListModel *AppInterface::simpleListModel() const
{
    return m_SimpleListModel;
}

void AppInterface::addLogLine()
{
    m_SimpleListModel->addLogLine("FirstnameNEW");
}

void AppInterface::external_addLogLine(const char* name)
{
    emit add(QString(name));
}


void AppInterface::internal_addLogLine(QString name)
{
    m_SimpleListModel->addLogLine(name);
}

void AppInterface::run_tests(){

    WorkerThread_test *workerThread = new WorkerThread_test;
    connect(workerThread, SIGNAL(finished()),
            workerThread, SLOT(deleteLater()));
    workerThread->start();

}

void AppInterface::run_app(){

    WorkerThread_app *workerThread = new WorkerThread_app;
    connect(workerThread, SIGNAL(finished()),
            workerThread, SLOT(deleteLater()));
    workerThread->start();

}

void AppInterface::stop_thread(){
    thread_should_exit = true;
}

void AppInterface::setLogPath(QString p)
{
    logpath = QUrl(p).toLocalFile();
}

void AppInterface::setConfigPath(QString p)
{
    confpath = QUrl(p).toLocalFile();
}
