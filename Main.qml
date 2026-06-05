import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia 5.15

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#000000"

    FontLoader { id: vcrFont; source: "VCR OSD Mono" }

    property string displayFont: vcrFont.status === FontLoader.Ready ? vcrFont.name : "VCR OSD Mono"
    property int sessIndex: 0
    property real fieldWidth: Math.min(width * 0.5, 640)

    ListModel { id: sessionList }

    function refreshSessions() {
        var sm = null
        try { sm = sessionModel } catch (e) {}
        if (!sm) { retryTimer.start(); return }

        var c = 0
        try { c = sm.count } catch (e) {}
        if (c < 1) { retryTimer.start(); return }

        sessionList.clear()
        var defaultIdx = -1
        for (var i = 0; i < c; i++) {
            var name = ""
            var key = ""
            try {
                var item = sm.get(i)
                name = item.name || ""
                key = item.key || ""
            } catch (e) {
                try { name = sm.data(sm.index(i, 0), 0) || "" } catch (e2) {}
                try { key = sm.data(sm.index(i, 0), 256) || "" } catch (e2) {}
            }
            if (!name) name = "WM " + (i + 1)

            sessionList.append({ sName: name, sKey: key })
            if (key.indexOf("hyprland-uwsm") !== -1) defaultIdx = i
        }

        if (defaultIdx < 0) defaultIdx = c > 1 ? 1 : 0
        sessIndex = defaultIdx
        try { sm.lastIndex = defaultIdx } catch (e) {}
    }

    Timer {
        id: retryTimer
        interval: 200
        repeat: false
        onTriggered: refreshSessions()
    }

    function cycleSession() {
        if (sessionList.count < 2) return
        var n = (sessIndex + 1) % sessionList.count
        sessIndex = n
        try { sessionModel.lastIndex = n } catch (e) {}
    }

    function doLogin() {
        var user = userModel ? userModel.lastUser : ""
        sddm.login(user, optionsInput.text, sessIndex)
    }

    Component.onCompleted: refreshSessions()

    Item {
        id: screenContainer
        anchors.fill: parent

        Video {
            id: backgroundVideo
            anchors.fill: parent
            source: "bg.mp4"
            fillMode: VideoOutput.PreserveAspectCrop
            autoPlay: true
            muted: true
            loops: MediaPlayer.Infinite

            property bool hasStarted: false

            onPlaying: hasStarted = true
            onStopped: { if (hasStarted) play() }
        }

        Item {
            id: uiLayer
            anchors.fill: parent

            Item {
                id: centerForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 60
                height: childrenRect.height

                Image {
                    id: logo
                    anchors.left: parent.left
                    anchors.leftMargin: 80
                    source: "logo.png"
                    width: Math.min(root.width * 0.55, 800)
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    id: diagnostics
                    anchors.top: logo.bottom
                    anchors.topMargin: 30
                    anchors.left: parent.left
                    anchors.leftMargin: 80
                    anchors.right: parent.right
                    anchors.rightMargin: 80
                    text: "EARLY_ACCESS READY\n\nSYSTEM V1 INITIALIZED\nDIAGNOSTICS... OK\nSTANDBY - WAIT FOR WAKE"
                    font.family: displayFont
                    font.pixelSize: 22
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignLeft
                }

                Column {
                    id: buttonColumn
                    anchors.top: diagnostics.bottom
                    anchors.topMargin: 35
                    anchors.left: parent.left
                    anchors.leftMargin: 80
                    width: Math.min(root.width * 0.42, 560)
                    spacing: 16

                    Rectangle {
                        id: playButton
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 110
                        radius: 14
                        border.width: 2
                        border.color: "#FFFFFF"
                        color: "#000000"

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            text: userModel && userModel.lastUser ? userModel.lastUser : "PLAYER"
                            font.family: displayFont
                            font.pixelSize: 36
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: optionsButton
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 110
                        radius: 14
                        border.width: optionsInput.activeFocus ? 5 : 2
                        border.color: "#FFFFFF"
                        color: "#000000"
                        Behavior on border.width { NumberAnimation { duration: 80 } }

                        TextField {
                            id: optionsInput
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            background: null
                            placeholderText: "ENTER PASSWORD"
                            placeholderTextColor: "#aaaaaa"
                            color: "#FFFFFF"
                            font.family: displayFont
                            font.pixelSize: 36
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            echoMode: TextInput.Password
                            focus: true

                            onAccepted: doLogin()
                        }

                        MouseArea {
                            id: optionsHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: optionsInput.forceActiveFocus()
                            cursorShape: Qt.IBeamCursor
                        }
                    }

                    Rectangle {
                        id: joinButton
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 110
                        radius: 14
                        border.width: joinHover.containsMouse ? 5 : 2
                        border.color: "#FFFFFF"
                        color: "#000000"
                        Behavior on border.width { NumberAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text: "MUSEUM (LOG IN)"
                            font.family: displayFont
                            font.pixelSize: 36
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            id: joinHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: doLogin()
                        }
                    }

                    Rectangle {
                        id: quitButton
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 110
                        radius: 14
                        border.width: quitHover.containsMouse ? 5 : 2
                        border.color: "#FFFFFF"
                        color: "#000000"
                        Behavior on border.width { NumberAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text: "QUIT"
                            font.family: displayFont
                            font.pixelSize: 36
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            id: quitHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: sddm.powerOff()
                        }
                    }
                }
            }

            Item {
                id: sessionFooter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 40
                anchors.rightMargin: 80
                anchors.bottomMargin: 40
                height: 100

                Text {
                    id: sessionsLabel
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    text: "INIT SESSIONS..."
                    font.family: displayFont
                    font.pixelSize: 20
                    color: "#555555"
                }

                Row {
                    id: sessionRow
                    anchors.top: sessionsLabel.bottom
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 24
                    visible: sessionList.count > 0

                    Repeater {
                        id: sessionRepeater
                        model: sessionList

                        delegate: Item {
                            width: nameText.implicitWidth + 30
                            height: 45

                            Text {
                                id: nameText
                                anchors.centerIn: parent
                                text: model.sName
                                font.family: root.displayFont
                                font.pixelSize: 22
                                color: index === root.sessIndex ? "#FFFFFF" : "#888888"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: -3
                                    height: index === root.sessIndex ? 3 : 1
                                    color: index === root.sessIndex ? "#FFFFFF" : "#555555"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.sessIndex = index
                                    try { sessionModel.lastIndex = index } catch (e) {}
                                }
                            }
                        }
                    }

                    Text {
                        text: "NO SESSIONS"
                        font.family: root.displayFont
                        font.pixelSize: 22
                        color: "#555555"
                        visible: sessionList.count === 0
                    }
                }
            }
        }

        Text {
            id: errorMessage
            anchors.centerIn: parent
            text: "ACCESS DENIED / ERROR"
            visible: false
            color: "#FF0000"
            font.family: displayFont
            font.pixelSize: 36
            font.bold: true
            z: 2
            horizontalAlignment: Text.AlignHCenter

            Timer {
                id: errorTimer
                interval: 5000
                onTriggered: errorMessage.visible = false
            }
        }
    }

    Connections {
        target: sddm
        onLoginFailed: {
            errorMessage.visible = true
            errorTimer.start()
        }
    }
}
