# Herdr Launcher

**A Dock icon for herdr on macOS.** Click it to open herdr in your terminal, or to bring the session that is already running back to the front.

[View on GitHub](https://github.com/Tatendaz/herdr-launcher) [Install](#install)

> **Unofficial.** This is a community project, not the official herdr launcher, and it is not affiliated with or endorsed by the herdr team. herdr, its name, and the ram logo belong to the [herdr project](https://github.com/ogulcancelik/herdr).

If you run herdr 0.7.5 or newer, herdr can install it for you:

```sh
herdr plugin install Tatendaz/herdr-launcher
```

## Who it is for

People who use [herdr](https://herdr.dev/) on a Mac and want it in the Dock like any other app. herdr is a terminal UI installed with `brew install herdr`, so there is no app bundle to keep there. This repo builds one.

## What a click does

- **herdr is not running.** Opens a new window in your terminal with herdr in it. If herdr is not installed, you get an alert with the install command instead.
- **herdr is running.** Brings your newest herdr session forward. In iTerm2 and Terminal.app that is the exact window and tab (and in iTerm2, the split pane). Ghostty, WezTerm, kitty, and Alacritty have no AppleScript interface for picking one window, so the whole app comes forward.
- **The running dot.** While herdr runs, the Dock tile shows the same running dot as any open app. A small launcher process polls every few seconds and quits shortly after your last herdr session exits, which clears the dot.

## Six terminals

iTerm2, Ghostty, WezTerm, kitty, Alacritty, and Terminal.app. On first launch a picker lists the supported terminals installed on your Mac and saves your choice to `~/.config/herdr-launcher/terminal`. Cancel it and the launcher uses the first one it finds, falling back to Terminal.app.

## Install

Needs macOS 12 or newer, herdr (`brew install herdr`), and a terminal. Terminal.app counts.

```sh
git clone https://github.com/Tatendaz/herdr-launcher.git
cd herdr-launcher
./build.sh --install
```

`build.sh` assembles `dist/Herdr.app` and `--install` copies it to `/Applications`. It uses only tools that ship with macOS (`osacompile`, `sips`, `iconutil`, `codesign`). Then drag `Herdr` from `/Applications` to the Dock.

With iTerm2 or Terminal.app, macOS asks once whether Herdr may control your terminal. Click Allow.

### Or let herdr install it

```sh
herdr plugin install Tatendaz/herdr-launcher
```

herdr shows the manifest's commands and asks before running anything. Confirming runs the same `./build.sh --install`.

## How it works

A stay-open AppleScript applet wrapped around a single shell script, `src/launcher.sh`, inside a macOS `.app` bundle. iTerm2 and Terminal.app are driven over AppleScript: the launcher opens a window and types the resolved herdr path into your login shell, so your rc files load. The other four terminals are started with `open` and the herdr binary as their command.

Only three files are specific to herdr, so the README explains how to point it at another CLI tool.

## Status

- **macOS only.** It drives terminals through AppleScript and `open`, which exist on no other OS.
- **Version 1.2.1 on `main`.** The only GitHub release is the older v0.1.0, so install from `main` as shown above.
- **Tested in CI on macOS.** `test.sh` checks shell syntax, the plist, AppleScript compilation, a full build, and the launcher's interface.
- **The icon is not MIT.** The ram is the herdr project's logo. The repo notes that permission to use it was requested from the herdr team on 2026-07-18.
- **Known edge.** If herdr runs inside a detached tmux session, the launcher cannot find its window and opens a new one instead.

---

**Built by Tatenda Zhou.** [tatendaz.github.io](https://tatendaz.github.io/) · [Follow on X](https://x.com/realtatendazhou) · [LinkedIn](https://www.linkedin.com/in/tatendazhou)

Need help making AI coding agents reliable? [tatendaz@me.com](mailto:tatendaz@me.com?subject=AI%20coding%20agents%20(via%20Herdr%20Launcher))

MIT licensed, except the herdr logo. Source on [GitHub](https://github.com/Tatendaz/herdr-launcher). [llms.txt](https://tatendaz.github.io/llms.txt)
