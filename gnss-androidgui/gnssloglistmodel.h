#include <QAbstractListModel>

class LogLineObj {
    public:
        LogLineObj(const QString &val):
            logline(val) {}

        QString logline;
};


class GnssLogListModel : public QAbstractListModel
{
    Q_OBJECT

    enum /*class*/ Roles {
        LOG_LINE = Qt::UserRole+1
    };

    public:
        GnssLogListModel(QObject *parent=0);
        QVariant data(const QModelIndex &index, int role) const;
        Q_INVOKABLE int rowCount(const QModelIndex &parent = QModelIndex()) const;
        QHash<int, QByteArray> roleNames() const;
        void addLogLine(QString line);

    private:
        Q_DISABLE_COPY(GnssLogListModel);
        QList<LogLineObj*> m_items;
};
