# Changelog

## 0.4.0

- **Super+S saves and copies the path.** The file's full path goes to the clipboard as text, ready to paste into a terminal, chat or file field. Turn it off with "Saving copies the file path".
- **Readable file names.** Saves are named `Framelet-2026-10-09_14-02-11.png`; a second capture in the same second becomes `…-2.png`. Nothing is overwritten.
- **History.** Saved captures, recordings and editable drafts by day, from the bar menu, `--history` or Ctrl+H in the window. Copy, open, reveal, resume or move to the Trash.
- **Delayed capture.** From the bar menu, Shift+Print (see `bindings.example.lua`), the Delay button or T in the selector: 3, 5 or 10 seconds, so menus and hover states stay open. `--delay N` works from scripts.
- **Shift snapping.** Hold Shift for 45° arrows and lines, squares and circles. Click inside a box to select it with a drawing tool.
- **Copy each capture right away** (off by default) puts the plain capture on the clipboard as soon as it is taken.
- **Portuguese.** A language setting (System, English, Português). The capture overlay, style panel, selection, countdown, recording controls, History and status messages are translated; the editor window stays in English. Thanks to @Dielerorn for the English pass (#1).
- **From Omaframe 0.8.0–0.10.0:** editor zoom and pan, repeated crops, a movable capture bar, clipboard-only copies, mic and computer sound meters, the system file chooser, and fixes. Long strokes are resampled instead of cut at 2048 points, scrolling capture keeps at most 400 MiB of frames, partial covers no longer count as hiding a secret, orphaned FFmpeg exports are cleaned up, and a stuck recorder can be force-stopped.
- Recording placement now recognises Framelet's own control windows, and the borderless Omarchy controls setting is respected.
- CI builds the plugin in an Arch container and runs the headless suites on every pull request and tag.
- **Updates rebuild the engine.** `build.sh` records the version it built, and the launcher rebuilds once (with a notification) when `omarchy plugin update` brings a new version, so the bar, overlay and engine never mismatch.

New dependency: `libpulse` (sound meters). `qt6-imageformats` adds WebP.

## 0.3.2

- Extend literal display text to status, palette-name and shared-button tooltips, whose Qt default also detects rich text.
- Add an offline regression for the actual tooltip component.

## 0.3.1

- Render annotation measurement and display labels as literal text, including imported file names, saved presets, paths and status messages. HTML-like input cannot turn these labels into remote image requests.
- Keep text editors and intentional code highlighting unchanged.
- Add offline regression checks for HTML-like annotations and file names.

## 0.3.0 — first Framelet release

- A single Omarchy plugin with inline capture, annotation and finishing.
- Original Framelet identity, bar symbol and atelier presentation.
- Smooth tapered brush, width/opacity controls and a separate uniform pen.
- Atelier, Graphite and Botanical palettes, plus saved custom palettes.
- Sketchbook, Ink and Gallery; optional paper grain and mat outside the captured pixels.
- Custom backgrounds, padding, corners, shadows, aspect ratios, title bars and reusable looks.
- Image composition, code cards, OCR and PNG/JPEG export at 1–3×.
- Automatic scrolling capture and recording inherited from Omaframe.
- Non-destructive migration from CapturaUnificada; existing Framelet files win.
- Source distribution with an explicit first-launch build and dependency documentation.

Based on Omaframe 0.7.4, MIT. Tested locally on x86_64, Omarchy 4.0.4 / Qt 6.11.2. See README for current limits and setup requirements.
