# Herdr Launcher

A Dock icon for [herdr](https://herdr.dev/). Click the ram, get herdr in a new terminal window.

> **This is not the official herdr launcher.** It is a community project, not affiliated with or endorsed by the herdr team. herdr itself, its name, and the ram logo belong to the [herdr project](https://github.com/ogulcancelik/herdr).

herdr is a terminal UI installed with `brew install herdr`, so there is no app to keep in the Dock. This repo builds one: a single shell script wrapped in a macOS `.app` bundle, with the herdr ram as its icon.

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

`build.sh` assembles `dist/Herdr.app` and `--install` copies it to `/Applications`. It uses only tools that ship with macOS (`sips`, `iconutil`, `codesign`), so there is nothing to install first.

Then put it in the Dock: open `/Applications` in Finder and drag `Herdr` to the Dock, or launch it once and choose Options > Keep in Dock from its Dock menu.

On first launch, macOS asks whether Herdr may control your terminal app. Click Allow. The permission lives under System Settings > Privacy & Security > Automation and is asked once.

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

## Adapting this for another CLI tool

Nothing here is specific to herdr beyond two files: `src/launcher.sh` (the command it types and the paths it probes) and `assets/icon-1024.png` (the Dock icon). Swap those, rename the bundle in `src/Info.plist` and `build.sh`, and rebuild.

## Icon

The ram is the herdr project's logo, rebuilt from [herdr.dev](https://herdr.dev/) assets in the site's header colors (`#1a1a18` on `#f5f3ee`). `assets/icon.svg` is the source; `build.sh` turns the 1024 px PNG export into the `.icns`. The herdr name and logo belong to the [herdr project](https://github.com/ogulcancelik/herdr); see [assets/README.md](assets/README.md).

## License

MIT for everything in this repo except the logo, which remains the herdr project's ([assets/README.md](assets/README.md)).
