import QtQuick
import Quickshell
import qs.Common
import qs.Services
pragma Singleton

Singleton {
    id: root

    property var profiles: []
    property string activeProfileName: ""
    property bool autoEnabled: false
    property string lastError: ""
    property string lastRefreshText: ""
    property bool refreshing: false
    property bool applying: false

    function refresh() {
        root.refreshing = true;
        Proc.runCommand("displayProfileService.status", ["dms", "ipc", "outputs", "status"], (stdout, exitCode) => {
            if (exitCode !== 0) {
                root.autoEnabled = false;
                root._refreshProfiles();
                return ;
            }
            const status = root._parseStatus(stdout);
            root.autoEnabled = status.autoEnabled;
            if (root.autoEnabled) {
                root.refreshing = false;
                root.profiles = [];
                root.activeProfileName = "";
                root.lastError = "";
                root.lastRefreshText = Qt.formatDateTime(new Date(), "HH:mm:ss");
                return ;
            }
            root._refreshProfiles();
        }, 50, 5000);
    }

    function _refreshProfiles() {
        Proc.runCommand("displayProfileService.listProfiles", ["dms", "ipc", "outputs", "listProfiles"], (stdout, exitCode) => {
            root.refreshing = false;
            if (exitCode !== 0) {
                root.lastError = stdout && stdout.length > 0 ? stdout.trim() : "dms ipc outputs listProfiles exited " + exitCode;
                return ;
            }
            const parsed = root._parseProfiles(stdout);
            root.profiles = parsed.profiles;
            root.activeProfileName = parsed.activeProfileName;
            root.lastError = parsed.profiles.length === 0 ? "No display profiles found" : "";
            root.lastRefreshText = Qt.formatDateTime(new Date(), "HH:mm:ss");
        }, 50, 5000);
    }

    function setProfile(profileName, onDone) {
        if (root.autoEnabled) {
            if (onDone)
                onDone(false);

            return ;
        }

        if (!profileName || profileName.length === 0) {
            ToastService.showError("Display profile switch failed", "Profile name is empty.");
            if (onDone)
                onDone(false);

            return ;
        }
        root.applying = true;
        Proc.runCommand("displayProfileService.setProfile", ["dms", "ipc", "outputs", "setProfile", profileName], (stdout, exitCode) => {
            root.applying = false;
            if (exitCode !== 0) {
                root.lastError = stdout && stdout.length > 0 ? stdout.trim() : "dms ipc outputs setProfile exited " + exitCode;
                ToastService.showError("Display profile switch failed", root.lastError);
                if (onDone)
                    onDone(false);

                return ;
            }
            root.lastError = "";
            root.activeProfileName = profileName;
            root._markActive(profileName);
            if (onDone)
                onDone(true);

        }, 50, 10000);
    }

    function nextProfileName() {
        if (root.autoEnabled)
            return "";

        if (!root.profiles || root.profiles.length === 0)
            return "";

        const index = root.profiles.findIndex((profile) => {
            return profile.name === root.activeProfileName;
        });
        const nextIndex = index < 0 ? 0 : (index + 1) % root.profiles.length;
        return root.profiles[nextIndex].name;
    }

    function outputsLabel(profile) {
        if (!profile || !profile.outputs || profile.outputs.length === 0)
            return "No outputs";

        return profile.outputs.join(", ");
    }

    function _markActive(profileName) {
        const next = [];
        for (let i = 0; i < root.profiles.length; i++) {
            const profile = root.profiles[i];
            next.push({
                "name": profile.name,
                "outputs": profile.outputs,
                "active": profile.name === profileName
            });
        }
        root.profiles = next;
    }

    function _parseProfiles(stdout) {
        const parsedProfiles = [];
        let activeProfileName = "";
        const lines = stdout.split(/\r?\n/);
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.length === 0)
                continue;

            const match = line.match(/^(.+?)\s*->\s*(.+)$/);
            if (!match)
                continue;

            const profileMatch = match[1].trim().match(/^(.+?)(?:\s+\[([^\]]+)\])?$/);
            if (!profileMatch)
                continue;

            const name = profileMatch[1].trim();
            const tags = profileMatch[2] ? profileMatch[2].split(",").map((tag) => {
                return tag.trim();
            }) : [];
            const active = tags.indexOf("active") !== -1;
            const outputs = root._parseOutputs(match[2].trim());
            parsedProfiles.push({
                "name": name,
                "outputs": outputs,
                "active": active
            });
            if (active)
                activeProfileName = name;

        }
        return {
            "profiles": parsedProfiles,
            "activeProfileName": activeProfileName
        };
    }

    function _parseStatus(stdout) {
        let autoEnabled = false;
        const lines = stdout.split(/\r?\n/);
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            const separator = line.indexOf(":");
            if (separator < 0)
                continue;

            const key = line.substring(0, separator).trim();
            const value = line.substring(separator + 1).trim();
            if (key === "auto")
                autoEnabled = value.toLowerCase() === "on";

        }
        return {
            "autoEnabled": autoEnabled
        };
    }

    function _parseOutputs(rawOutputs) {
        try {
            const parsed = JSON.parse(rawOutputs);
            if (Array.isArray(parsed))
                return parsed.map((output) => {
                return String(output);
            });

        } catch (e) {
        }
        const stripped = rawOutputs.replace(/^\[/, "").replace(/\]$/, "");
        if (stripped.trim().length === 0)
            return [];

        return stripped.split(",").map((output) => {
            return output.trim().replace(/^["']|["']$/g, "");
        }).filter((output) => {
            return output.length > 0;
        });
    }

}
