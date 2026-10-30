# RELEASE — packaging, GitHub, itch.io, Steam Deck

Version on title screen: 0.3.0-c1. This is a vertical slice, not a
release candidate; do not publish it as a finished game.

## Build (reproducible)
```sh
tools/build.sh
# or manually:
godot --headless --path . --import
godot --headless --path . -s tests/test_battle.gd
python3 tools/validate_content.py
godot --headless --path . --export-release "Web" dist/web/index.html
godot --headless --path . --export-release "Linux" dist/linux/echoes-of-the-last-dawn.x86_64
```
Godot version pinned: 4.7.2 stable, templates in
`~/.local/share/godot/export_templates/4.7.2.stable/`.

## Packages (produced by tools/build.sh)
- Web: `dist/echoes-web.zip` — index.html at the root, with index.js,
  index.wasm, index.pck and support files, relative paths, no enclosing
  directory, no cross-origin headers required (single-threaded build).
- Linux: `dist/echoes-linux.tar.gz` — executable (permission preserved
  in tar) + matching .pck, no machine-specific absolute paths.
- Checksums: `dist/SHA256SUMS`.

## itch.io (not yet published — needs Jimmy's confirmation)
1. Create a project on itch.io (or confirm the existing one) and note
   its URL slug.
2. Upload the Web ZIP to a **browser** channel and the Linux tar.gz to
   a **Linux** channel (separate channels).
3. Embed settings tested locally: single-threaded build, canvas resize
   policy 2, focus canvas on start. Fullscreen button is the engine's
   default in the shell.
4. Butler (placeholders only, no token in this repo):
```sh
# butler push dist/echoes-web.zip <account>/<project>:web
# butler push dist/echoes-linux.tar.gz <account>/<project>:linux
```
Butler is installed at ~/workspace/tools/butler for when a destination
is confirmed.

## GitHub (not yet created — needs Jimmy's confirmation)
Do NOT push to an unknown remote. When Jimmy confirms a repo name:
```sh
git remote add origin git@github.com:OuterHeavenX/<repo>.git
git push -u origin main
```
CI (to be added with the repo): pin Godot 4.7.2 + templates, import,
run tests + validator, export Web + Linux, upload artifacts. The repo
must be created by Jimmy (this connection cannot create repos), and
Pages, if used, is flipped on by him.

## Steam Deck installation (documented, untested on hardware)
1. Extract the Linux tar.gz in Desktop Mode.
2. Launch `echoes-of-the-last-dawn.x86_64` once from Desktop Mode to
   confirm it runs.
3. In Steam, Add a Non-Steam Game → select the executable.
4. In Gaming Mode, select the game → controller layout: Gamepad with
   Joystick Trackpad off is fine; in-game prompts use A/B/X/Y as above.
5. Return to Gaming Mode and launch. No Proton is needed or recommended
   for this native Linux build.
Known issue: first launch may show audio warnings on systems without
a sound device; the game falls back to the dummy audio driver.
