import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    pluginId: "displayProfileManager"
    Component.onCompleted: DisplayProfileService.refresh()

    StyledText {
        text: "Display Profile Manager"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "pollingEnabled"
        label: "Periodic polling"
        description: "Periodically refresh profile state in the background. Turning this off stops refresh interval updates."
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "abbreviateProfileNames"
        label: "Abbreviate profile names"
        description: "Show only the initials of the active profile in the bar."
        defaultValue: false
    }

    StyledRect {
        width: parent.width
        height: generalCol.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: generalCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.spacingL
            anchors.rightMargin: Theme.spacingL
            anchors.topMargin: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "General"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            SliderSetting {
                settingKey: "pollIntervalSeconds"
                label: "Refresh interval"
                description: "How often to call dms ipc outputs listProfiles."
                defaultValue: 15
                minimum: 5
                maximum: 120
                unit: "s"
            }

        }

    }

    StyledRect {
        width: parent.width
        height: statusCol.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: statusCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.spacingL
            anchors.rightMargin: Theme.spacingL
            anchors.topMargin: Theme.spacingL
            spacing: Theme.spacingM

            Row {
                width: parent.width
                spacing: Theme.spacingM

                StyledText {
                    text: "Profiles"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    width: parent.width - refreshButton.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                }

                DankButton {
                    id: refreshButton

                    text: DisplayProfileService.refreshing ? "Refreshing" : "Refresh"
                    iconName: "refresh"
                    enabled: !DisplayProfileService.refreshing
                    onClicked: DisplayProfileService.refresh()
                }

            }

            StyledText {
                text: DisplayProfileService.lastError.length > 0 ? DisplayProfileService.lastError : (DisplayProfileService.activeProfileName.length > 0 ? "Active: " + DisplayProfileService.activeProfileName : "No active profile")
                font.pixelSize: Theme.fontSizeSmall
                color: DisplayProfileService.lastError.length > 0 ? Theme.error : Theme.surfaceTextMedium
                width: parent.width
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: DisplayProfileService.profiles

                delegate: StyledRect {
                    id: row

                    required property var modelData

                    width: parent.width
                    height: 48
                    radius: Theme.cornerRadius
                    color: row.modelData.active ? Theme.withAlpha(Theme.primary, 0.16) : Theme.nestedSurface
                    border.width: row.modelData.active ? 1 : 0
                    border.color: row.modelData.active ? Theme.primary : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        spacing: Theme.spacingM

                        DankIcon {
                            name: row.modelData.active ? "check_circle" : "settings_input_hdmi"
                            color: row.modelData.active ? Theme.primary : Theme.surfaceTextMedium
                            size: Theme.iconSize - 2
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingM
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: row.modelData.name
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: row.modelData.active ? Font.Bold : Font.Medium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                width: parent.width
                            }

                            StyledText {
                                text: DisplayProfileService.outputsLabel(row.modelData)
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceTextMedium
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                width: parent.width
                            }

                        }

                    }

                }

            }

        }

    }

}
