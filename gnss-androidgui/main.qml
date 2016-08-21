import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2

Item {
    id: applicationWindow1
    visible: true
    width: 720
    height: 1280
    anchors.fill: parent
    Keys.enabled: true
    Keys.priority: Keys.BeforeItem

    Keys.onReleased: {
        console.log("back");
        if (event.key === Qt.Key_Back) {
            event.accepted=true;
        }
    }

    ScrollView{
        anchors.rightMargin: 10
        anchors.leftMargin: 10
        anchors.bottomMargin: 10
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.top: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        //horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOn;
        ListView {
            id: myListView

            delegate: Text { text: logline }

            model: AppInterface.simpleListModel
        }
    }

    Button {
        id: button3
        x: 479
        y: 123
        text: qsTr("Run tests")
        onClicked: AppInterface.run_tests()
    }

    Button {
        id: button4
        x: 480
        y: 159
        text: qsTr("Run gnss-sdr")
        onClicked: AppInterface.run_app()
    }


    Button {
        id: button1
        x: 376
        y: 116
        text: qsTr("Change")
        anchors.verticalCenterOffset: 0
        anchors.verticalCenter: textField1.verticalCenter
        onClicked: fileDialog.visible = true;
    }


    FileDialog {
        id: fileDialog
        title: "Please choose a file"
        folder: shortcuts.home
        onAccepted: {
            textField1.text = fileDialog.fileUrl
            AppInterface.setConfigPath(fileDialog.fileUrl);
        }
        onRejected: {
            console.log("Canceled")
        }
        //Component.onCompleted: visible = true
    }

    FileDialog {
        id: fileDialog2
        title: "Please choose a folder"
        folder: shortcuts.home
        selectFolder: true
        onAccepted: {
            textField2.text = fileDialog2.fileUrl
            AppInterface.setLogPath(fileDialog2.fileUrl);
        }
        onRejected: {
            console.log("Canceled")
        }
        //Component.onCompleted: visible = true
    }


    TextField {
        id: textField1
        x: 157
        y: 123
        width: 200
        height: 25
        text: "/sdcard/foo"
        placeholderText: qsTr("Text Field")
        enabled: false
    }

    Label {
        id: label1
        x: 92
        y: 130
        text: qsTr("Config File Path")
        anchors.verticalCenterOffset: 0
        anchors.verticalCenter: textField1.verticalCenter
        anchors.right: textField1.left
        anchors.rightMargin: 5
    }

    Button {
        id: button2
        x: 376
        y: 228
        text: qsTr("Change")
        anchors.verticalCenterOffset: 0
        anchors.verticalCenter: textField2.verticalCenter
        onClicked: fileDialog2.visible = true;
    }

    TextField {
        id: textField2
        x: 157
        y: 158
        width: 200
        text: "/sdcard/foo"
        placeholderText: qsTr("Text Field")
        enabled: false
    }

    Label {
        id: label2
        x: 89
        y: 165
        text: qsTr("Log output Path")
        anchors.verticalCenterOffset: 0
        anchors.right: textField2.left
        anchors.rightMargin: 5
        anchors.verticalCenter: textField2.verticalCenter
    }

    Button {
        id: button6
        x: 576
        y: 159
        text: qsTr("Stop")
        onClicked: AppInterface.stop_thread()
    }

    Connections {
        target: AppInterface
        onDeviceCountChanged: {
            text_devcount.text = n
        }
    }

    Text {
        id: text_devcount
        x: 300
        y: 236
        text: qsTr("Text")
        font.pixelSize: 12
    }

}
