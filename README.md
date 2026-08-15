# Herdr Launcher

A Dock icon for [herdr](https://herdr.dev/). Click the ram, get herdr: a new terminal window when none is running, the window you already have brought back to the front when one is — and the Dock's running dot while herdr is up.

> **This is not the official herdr launcher.** It is a community project, not affiliated with or endorsed by the herdr team. herdr itself, its name, and the ram logo belong to the [herdr project](https://github.com/ogulcancelik/herdr).

herdr is a terminal UI installed with `brew install herdr`, so there is no app to keep in the Dock. This repo builds one: a stay-open AppleScript applet wrapped around a single shell script in a macOS `.app` bundle, with the herdr ram as its icon.

## Requirements

- macOS 12 or newer. The launcher is macOS only: it drives terminals through AppleScript and `open`, which exist on no other OS.
- herdr itself: `brew install herdr`
- A terminal. Terminal.app counts, so this is already true.

## Install

```sh
git clone https://github.com/Tatendaz/herdr-launcher.git
cd herdr-launcher
./build.sh --install
```

`build.sh` assembles `dist/Herdr.app` and `--install` copies it to `/Applications`. It uses only tools that ship with macOS (`osacompile`, `sips`, `iconutil`, `codesign`), so there is nothing to install first.

Then put it in the Dock: open `/Applications` in Finder and drag `Herdr` to the Dock, or launch it once and choose Options > Keep in Dock from its Dock menu.

On first launch with iTerm2 or Terminal.app — the two terminals driven over AppleScript — macOS asks whether Herdr may control your terminal. Click Allow. The permission lives under System Settings > Privacy & Security > Automation and is asked once. The other four terminals are started with `open` and need no permission. Bringing an existing session's window forward works the same way: scripted for iTerm2 and Terminal.app under the same permission, `open` for the rest.

### Or let herdr install it

The repo is also a herdr [workflow plugin](https://herdr.dev/docs/plugins/), so herdr 0.7.5 or newer can install it directly:

```sh
herdr plugin install Tatendaz/herdr-launcher
```

herdr shows the manifest's commands and asks before running anything; confirming runs the same `./build.sh --install`, which ends with `Herdr.app` in `/Applications`. The plugin exposes two actions, `install` and `uninstall`, to rebuild or remove the app later without leaving herdr.

## The Dock running dot

While herdr runs, the Dock tile carries the same running indicator as any other open app. Clicking the ram launches herdr and leaves a small launcher process resident; it polls every few seconds and quits itself shortly after your last herdr session exits, which is when the dot disappears. Clicking the icon while the dot is showing brings the running session's window back to the front instead of opening another one.

Two edges worth knowing:

- The dot tracks herdr processes, not windows: any number of sessions keep it lit, and it clears a few seconds after the last one ends.
- A herdr session started from a shell by hand cannot light the dot on its own — only clicking the icon starts the launcher process. While the launcher is already resident, though, every herdr session counts, hand-started ones included. Right-clicking the Dock icon and choosing Quit removes the dot without touching running herdr sessions.

## Clicking while herdr is already running

A click on the ram only opens a new terminal window when no herdr process exists. Otherwise it finds your newest herdr session and brings it forward:

- In iTerm2 and Terminal.app, the exact window and tab (and, in iTerm2, split pane) running herdr is selected, unminiaturizing its window if needed.
- Ghostty, WezTerm, kitty, and Alacritty have no AppleScript interface to pick one window, so their whole app is brought forward instead.
- Hand-started sessions count too: click the ram while a shell-launched herdr runs and the launcher adopts it — its window comes forward and the Dock dot lights.

When the session's window cannot be located — say herdr runs inside a detached tmux session — the click falls back to opening a new window. To open a second session deliberately while one is running, start `herdr` from any shell; the dot counts it all the same.

## Which terminal it opens, and how to change it

Six terminals are supported: iTerm2, Ghostty, WezTerm, kitty, Alacritty, and Terminal.app. The launcher picks one in this order:

1. **Your saved choice**: `~/.config/herdr-launcher/terminal`, if that file exists and names a terminal that is still installed. A stale or unrecognized value is ignored, which brings the picker back.
2. **First-run picker**: with no (valid) saved choice, a dialog lists the supported terminals installed on your Mac. Picking one saves it to the file above, so the dialog appears once.
3. **Auto-detect**: if you cancel the picker, the launcher uses the first of iTerm2, Ghostty, WezTerm, kitty, Alacritty it finds installed, then Terminal.app. Cancelling saves nothing, so the picker returns on the next launch.

To change the default terminal later, overwrite the config file, or delete it to get the picker again:

```sh
echo ghostty > ~/.config/herdr-launcher/terminal   # switch directly
rm ~/.config/herdr-launcher/terminal               # re-run the picker on next launch
```

| Value | Opens |
|------------|--------------|
| `iterm` | iTerm2 |
| `ghostty` | Ghostty |
| `wezterm` | WezTerm |
| `kitty` | kitty |
| `alacritty` | Alacritty |
| `terminal` | Terminal.app |

iTerm2 and Terminal.app are driven over AppleScript: the launcher opens a new window and types the resolved herdr path into your login shell, so your rc files load and the binary the launcher verified is the one that runs. The other four have no AppleScript interface, so the launcher starts them with the binary as their command, e.g. `open -na Ghostty --args -e /opt/homebrew/bin/herdr`.

If herdr is not installed, the launcher shows an alert with the install command instead of opening a terminal. If a terminal fails to open (the usual cause is a denied Automation permission), the error appears in an alert rather than vanishing.

## Uninstall

```sh
rm -rf /Applications/Herdr.app
rm -rf ~/.config/herdr-launcher   # only if you created the config file
```

If the Dock dot is showing, also right-click the icon and choose Quit; deleting the bundle does not stop the already-running launcher process.

## Adapting this for another CLI tool

Nothing here is specific to herdr beyond three files: `src/launcher.sh` (the command it types, the paths it probes, and the process name inside its `herdr_running` and `focus_herdr` checks — what the Dock dot tracks and what clicks jump back to), `assets/icon-1024.png` (the Dock icon), and `herdr-plugin.toml` (the herdr plugin manifest — rewrite it for your tool's ecosystem, or delete it). Swap those, rename the bundle in `src/Info.plist` and `build.sh`, and rebuild; `src/main.applescript` is generic and needs no changes.

## Icon

The ram is the herdr project's logo, rebuilt from [herdr.dev](https://herdr.dev/) assets in the site's header colors (`#1a1a18` on `#f5f3ee`). `assets/icon.svg` is the source; `build.sh` turns the 1024 px PNG export into the `.icns`. The herdr name and logo belong to the [herdr project](https://github.com/ogulcancelik/herdr); see [assets/README.md](assets/README.md).

## License

MIT for everything in this repo except the logo, which remains the herdr project's ([assets/README.md](assets/README.md)).
