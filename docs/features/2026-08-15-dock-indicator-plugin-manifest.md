# Dock running indicator and herdr plugin manifest

Two changes that ready the repo for a herdr marketplace listing.

## Dock running indicator

`Herdr.app` is now a stay-open AppleScript applet instead of a bare script
bundle. Clicking the icon still opens herdr in the chosen terminal through
the same `launcher.sh`, but the applet then stays resident while the user
has a `herdr` process, which is what lights the standard macOS open-app dot
under the Dock tile.

Mechanics:

- `launcher.sh --launch-and-wait` launches as before, then blocks until a
  `herdr` process exists (30 s cap, `HERDR_LAUNCH_WAIT_SECS` overrides), so
  the applet cannot mistake "terminal still starting" for "herdr quit".
- `launcher.sh --herdr-running` is the liveness probe the applet polls every
  3 seconds from `on idle`; when it fails, the applet quits and the dot
  clears. It matches by process name (`pgrep -x herdr`) for the current
  user, so any herdr session keeps the dot lit, not just launcher-started
  ones.
- Dock clicks while resident arrive as `reopen` events and open another
  herdr window, preserving the click-the-ram contract.
- The applet keeps no top-level AppleScript state: stay-open applets write
  properties back into their compiled script on quit, which would break the
  bundle's code signature.
- `LSUIElement` is gone from `Info.plist` (the Dock only draws the
  indicator for regular apps) and `OSAAppletStayOpen` is set instead.
  Versions bump to 1.1.0 / build 2.

## herdr plugin manifest

`herdr-plugin.toml` declares the repo as a macOS-only herdr workflow plugin
(id `tatendaz.herdr-launcher`, `min_herdr_version` 0.7.5, the herdr version
the manifest was validated against). `herdr plugin install
Tatendaz/herdr-launcher` builds and installs the app after herdr's usual
command preview; `install` and `uninstall` actions cover later rebuilds and
removal from inside herdr. Marketplace listing itself only needs the
`herdr-plugin` GitHub topic once the repo owner flips it on.
