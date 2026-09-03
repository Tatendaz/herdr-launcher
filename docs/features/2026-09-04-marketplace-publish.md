# Marketplace publish release

The version herdr's marketplace will index as the plugin's first listed
release. No behavior changes: versions bump to 1.2.1 / build 4 in
`src/Info.plist` and `herdr-plugin.toml` so the listing, the manifest, and
the installed bundle all name the same release.

Publishing itself is repo metadata, not code: after this merges, adding
the `herdr-plugin` GitHub topic makes the marketplace index the repo
automatically (public non-fork repo + valid manifest + topic; the listing
appears within about 30 minutes, no submission step).
