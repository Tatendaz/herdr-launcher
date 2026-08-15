-- Herdr.app applet: the resident process behind the Dock icon.
--
-- macOS draws its running indicator under a Dock tile only while the app's
-- process is alive, so the applet stays open while herdr runs and quits
-- once it is gone. Everything herdr-specific lives in launcher.sh, bundled
-- next to this script; the handlers here only decide when to call it and
-- when to quit.
--
-- No properties and no globals: stay-open applets write top-level state
-- back into their compiled script on quit, which would break the bundle's
-- code signature.

on launcherCommand(mode)
	return quoted form of (POSIX path of (path to me) & "Contents/Resources/launcher.sh") & " " & mode
end launcherCommand

-- Surface herdr: launcher.sh brings the running session's window forward,
-- or launches herdr and waits for its process, so the first idle poll
-- cannot land in the gap where the terminal is open but herdr is not up.
on launchHerdr()
	try
		do shell script launcherCommand("--launch-and-wait")
		return true
	on error
		return false
	end try
end launchHerdr

on run
	if not launchHerdr() then quit
end run

-- A Dock click on a running app arrives as reopen: same contract as the
-- first click — surface herdr, reusing the session already on screen.
on reopen
	launchHerdr()
end reopen

on idle
	try
		do shell script launcherCommand("--herdr-running")
	on error
		quit
	end try
	return 3
end idle
