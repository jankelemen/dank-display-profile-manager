import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginComponent {
    id: root

    readonly property int pollIntervalSeconds: Math.max(1, (pluginData && pluginData.pollIntervalSeconds) || 15)
    readonly property bool pollingEnabled: !pluginData || pluginData.pollingEnabled !== false
    readonly property var profiles: DisplayProfileService.profiles || []
    readonly property bool autoEnabled: DisplayProfileService.autoEnabled
    readonly property string activeProfileName: DisplayProfileService.activeProfileName
    readonly property var activeProfile: {
        const profile = root.profiles.find((p) => {
            return p.name === root.activeProfileName;
        });
        return profile || null;
    }

    function setProfile(profile) {
        if (!profile || profile.name === root.activeProfileName)
            return ;

        DisplayProfileService.setProfile(profile.name, (success) => {
            if (success)
                postClickRefresh.restart();

        });
    }

    function cycleProfile() {
        const nextName = DisplayProfileService.nextProfileName();
        if (nextName.length === 0)
            return ;

        const profile = root.profiles.find((p) => {
            return p.name === nextName;
        });
        if (profile)
            root.setProfile(profile);

    }

    function displayName() {
        if (root.autoEnabled)
            return "Auto";

        return root.activeProfileName.length > 0 ? root.activeProfileName : "No profile";
    }

    function detailText() {
        if (root.autoEnabled)
            return "Auto profile selection is on";

        return root.activeProfile ? DisplayProfileService.outputsLabel(root.activeProfile) : (DisplayProfileService.lastError.length > 0 ? DisplayProfileService.lastError : "Waiting for profiles");
    }

    layerNamespacePlugin: "displayProfileManager"
    pillRightClickAction: function() {
        root.cycleProfile();
    }
    popoutWidth: 420
    popoutHeight: Math.max(236, Math.min(476, 172 + root.profiles.length * 64))

    Timer {
        id: startupRefresh

        property int remainingAttempts: 6

        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (DisplayProfileService.autoEnabled || DisplayProfileService.profiles.length > 0 || DisplayProfileService.activeProfileName.length > 0 || startupRefresh.remainingAttempts <= 0) {
                startupRefresh.stop();
                return ;
            }

            if (DisplayProfileService.refreshing)
                return ;

            startupRefresh.remainingAttempts -= 1;
            DisplayProfileService.refresh();
        }
    }

    Timer {
        interval: root.pollIntervalSeconds * 1000
        running: root.pollingEnabled
        repeat: true
        triggeredOnStart: false
        onTriggered: DisplayProfileService.refresh()
    }

    Timer {
        id: postClickRefresh

        interval: 400
        repeat: false
        onTriggered: DisplayProfileService.refresh()
    }

    Timer {
        id: manualRefresh

        interval: 120
        repeat: false
        onTriggered: DisplayProfileService.refresh()
    }

    Process {
        id: toggleAutoProcess

        command: ["dms", "ipc", "outputs", "toggleAuto"]
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                DisplayProfileService.lastError = "dms ipc outputs toggleAuto exited " + exitCode;
                return ;
            }
            DisplayProfileService.lastError = "";
            DisplayProfileService.refresh();
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                name: DisplayProfileService.lastError.length > 0 ? "warning" : "desktop_windows"
                color: DisplayProfileService.lastError.length > 0 ? Theme.error : Theme.surfaceText
                size: Theme.iconSize - 6
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.displayName()
                color: DisplayProfileService.lastError.length > 0 ? Theme.error : Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                maximumLineCount: 1
                anchors.verticalCenter: parent.verticalCenter
            }

        }

    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: DisplayProfileService.lastError.length > 0 ? "warning" : "desktop_windows"
                color: DisplayProfileService.lastError.length > 0 ? Theme.error : Theme.surfaceText
                size: Theme.iconSize - 6
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.displayName()
                color: DisplayProfileService.lastError.length > 0 ? Theme.error : Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                maximumLineCount: 1
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            showCloseButton: false
            spacing: Theme.spacingM
            Component.onCompleted: DisplayProfileService.refresh()

            Row {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 44
                spacing: Theme.spacingM

                DankIcon {
                    name: DisplayProfileService.lastError.length > 0 ? "warning" : "desktop_windows"
                    size: Theme.iconSizeLarge
                    color: DisplayProfileService.lastError.length > 0 ? Theme.error : Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    spacing: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Theme.iconSizeLarge - closeButton.width - Theme.spacingM * 2

                    StyledText {
                        text: root.displayName()
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                        color: DisplayProfileService.lastError.length > 0 ? Theme.error : Theme.surfaceText
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        width: parent.width
                    }

                    StyledText {
                        text: root.detailText()
                        font.pixelSize: Theme.fontSizeSmall
                        color: DisplayProfileService.lastError.length > 0 ? Theme.error : Theme.surfaceTextMedium
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        width: parent.width
                    }

                }

                Rectangle {
                    id: closeButton

                    width: 32
                    height: 32
                    radius: 16
                    color: closeArea.containsMouse ? Theme.errorHover : "transparent"
                    anchors.top: parent.top

                    DankIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: Theme.iconSize - 4
                        color: closeArea.containsMouse ? Theme.error : Theme.surfaceText
                    }

                    MouseArea {
                        id: closeArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: {
                            if (popout.closePopout)
                                popout.closePopout();

                        }
                    }

                }

            }

            Column {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingS

                StyledRect {
                    width: parent.width
                    height: 72
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    visible: root.autoEnabled

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "auto_mode"
                            color: Theme.primary
                            size: Theme.iconSize
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingM
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: "Auto profile selection is on"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                width: parent.width
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            StyledText {
                                text: "Profiles can't be selected"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceTextMedium
                                width: parent.width
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                        }

                    }

                }

                Repeater {
                    model: root.autoEnabled ? [] : root.profiles

                    delegate: StyledRect {
                        id: profileRow

                        required property var modelData

                        width: parent.width
                        height: 56
                        radius: Theme.cornerRadius
                        color: {
                            if (profileRow.modelData.active)
                                return Theme.withAlpha(Theme.primary, 0.16);

                            if (rowArea.containsMouse)
                                return Theme.nestedSurface;

                            return Theme.surfaceContainerHigh;
                        }
                        border.width: profileRow.modelData.active ? 1 : 0
                        border.color: profileRow.modelData.active ? Theme.primary : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            DankIcon {
                                name: profileRow.modelData.active ? "check_circle" : "settings_input_hdmi"
                                color: profileRow.modelData.active ? Theme.primary : Theme.surfaceTextMedium
                                size: Theme.iconSize
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: parent.width - Theme.iconSize - Theme.spacingM
                                spacing: Theme.spacingXS
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    text: profileRow.modelData.name
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: profileRow.modelData.active ? Font.Bold : Font.Medium
                                    color: Theme.surfaceText
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    width: parent.width
                                }

                                StyledText {
                                    text: DisplayProfileService.outputsLabel(profileRow.modelData)
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceTextMedium
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    width: parent.width
                                }

                            }

                        }

                        MouseArea {
                            id: rowArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !DisplayProfileService.refreshing && !DisplayProfileService.applying
                            onClicked: root.setProfile(profileRow.modelData)
                        }

                    }

                }

                StyledRect {
                    width: parent.width
                    height: 56
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    visible: !root.autoEnabled && root.profiles.length === 0

                    StyledText {
                        anchors.centerIn: parent
                        width: parent.width - Theme.spacingL * 2
                        text: DisplayProfileService.lastError.length > 0 ? DisplayProfileService.lastError : "No display profiles found"
                        color: DisplayProfileService.lastError.length > 0 ? Theme.error : Theme.surfaceTextMedium
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        maximumLineCount: 2
                    }

                }

            }

            Row {
                width: parent.width - Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 40
                spacing: Theme.spacingS

                DankButton {
                    text: DisplayProfileService.refreshing ? "Refreshing" : "Refresh"
                    iconName: "refresh"
                    enabled: !DisplayProfileService.refreshing
                    onClicked: manualRefresh.restart()
                }

                DankButton {
                    text: toggleAutoProcess.running ? "Toggling" : (root.autoEnabled ? "Disable auto" : "Enable auto")
                    iconName: "toggle_off"
                    enabled: !toggleAutoProcess.running
                    onClicked: toggleAutoProcess.running = true
                }

                StyledText {
                    text: DisplayProfileService.lastRefreshText.length > 0 ? "Updated " + DisplayProfileService.lastRefreshText : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceTextMedium
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text.length > 0
                }

            }

            Item {
                width: 1
                height: Theme.spacingXS
            }

        }

    }

}
