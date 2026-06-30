# display-profile-manager

A [Dank Material Shell][dms] plugin for selecting DMS output profiles from the DankBar.

The widget reads profiles with:

```sh
dms ipc outputs listProfiles
```

and switches profiles with:

```sh
dms ipc outputs setProfile <profile>
```

## Features

- Shows the active display profile in the bar.
- Lists every DMS output profile in the popout.
- Marks the active profile with a check indicator.
- Switches profiles from the popout.
- Cycles to the next profile from the pill right-click action.
- Polls profile state every 15 seconds by default.
- Exposes the polling interval as a settings slider. Polling can also be disabled.

## Install

### Automatic

```sh
dms plugins install displayProfileManager
```

### Manual

Symlink the plugin into DMS:

```sh
git clone https://github.com/jankelemen/dank-display-profile-manager.git
ln -s "$PWD/dank-display-profile-manager" ~/.config/DankMaterialShell/plugins/dank-display-profile-manager
```

Then open DMS settings, scan for plugins, enable **Display Profile Manager**, and add it to the DankBar widget list.

## Configuration

Settings live in **DMS Settings -> Plugins -> Display Profile Manager**.

- **Refresh interval**: how often the plugin calls `dms ipc outputs listProfiles`; default is 15 seconds.
- **Periodic polling**: enables or disables background refreshes. Manual refresh and profile switching still refresh state.

Profiles themselves are managed by DMS outputs. This plugin only displays and selects them.

## Troubleshooting

- **No profiles shown**: run `dms ipc outputs listProfiles` in a terminal and confirm it returns profile lines.
- **Switching fails**: run `dms ipc outputs setProfile <profile>` manually and check the error from DMS.

## Development

There is no build toolchain. DMS loads the QML at runtime.

```sh
dms ipc call plugins reload displayProfileManager
```

[dms]: https://github.com/AvengeMedia/DankMaterialShell
