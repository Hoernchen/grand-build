#include "gnssloglistmodel.h"

GnssLogListModel::GnssLogListModel(QObject *parent) :
    QAbstractListModel(parent)
{
}

QHash<int, QByteArray> GnssLogListModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[LOG_LINE] = "logline";

    return roles;
}

void GnssLogListModel::addLogLine(QString line)
{
    LogLineObj *dataObject = new LogLineObj(line);
    beginInsertRows(QModelIndex(),m_items.size(),m_items.size());
    m_items.append(dataObject);
    endInsertRows();

}

int GnssLogListModel::rowCount(const QModelIndex &) const
{
    return m_items.size();
}

QVariant GnssLogListModel::data(const QModelIndex &index, int role) const
{
    if(!index.isValid())
        return QVariant();

    if(index.row() > (m_items.size() - 1))
        return QVariant();

    LogLineObj *dobj = m_items.at(index.row());

    switch (role)
    {
        case LOG_LINE:
            return QVariant::fromValue(dobj->logline);

        default:
            return QVariant();
    }
}
