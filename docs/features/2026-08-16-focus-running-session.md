# Dock clicks focus the running herdr session

Clicking the ram while herdr is already running now brings the existing
session's window back to the front instead of opening another terminal
window. A fresh launch only happens when no herdr process exists (or when
the running one has no window to find, e.g. inside a detached tmux
session). Running `launcher.sh` with no argument still always opens a new
window, which is also the escape hatch for deliberately starting a second
session.

Mechanics, all inside `launcher.sh` so the applet is unchanged apart from
comments:

- `--launch-and-wait` (what the applet runs for every Dock click) first
  tries `focus_herdr` and exits 0 when it succeeds.
- `focus_herdr` finds the newest herdr process (`pgrep -n`), reads its
  controlling tty, and identifies the hosting terminal by walking the
  process ancestry until a known terminal's `.app` bundle path appears in
  `comm` (`terminal_of_pid`). The walk correctly passes through
  intermediaries like iTerm2's session-restoration server.
- iTerm2 and Terminal.app are focused precisely: an AppleScript snippet
  matches the tty against every session/tab, selects the window, tab, and
  (in iTerm2) split pane, unminiaturizes, and activates. The other four
  terminals have no AppleScript interface, so their app is activated with
  `open -a`.
- Hand-started herdr sessions are adopted: clicking the ram focuses them
  and lights the dot rather than stacking a second session on top.
- No new permissions: focusing scripts the same two terminals launching
  already scripts, under the same Automation grant.

Versions bump to 1.2.0 / build 3; the plugin manifest description now
reflects the focus behavior.
