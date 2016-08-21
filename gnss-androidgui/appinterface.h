#include <QObject>
#include "gnssloglistmodel.h"

class AppInterface : public QObject
{
    Q_OBJECT
    Q_PROPERTY(GnssLogListModel *simpleListModel READ simpleListModel CONSTANT)

    public:
        explicit AppInterface(QObject *parent = 0);
        GnssLogListModel *simpleListModel() const;

    public slots:
        void addLogLine();
        void external_addLogLine(const char *name);

        void run_tests();
        void stop_thread();
        void setLogPath(QString p);
        void setConfigPath(QString p);
        void run_app();
private:
        GnssLogListModel *m_SimpleListModel;


private slots:
          void internal_addLogLine(QString l);
signals:
          void add(QString l);
          void deviceCountChanged(int n);

};
