# Launch artwork

The approved Framelet symbol is preserved in `assets/`. This presentation extends the existing atelier identity; it does not replace the native application design.

`cover.svg` is the editable source for the root `preview.png`. `demo.svg` produces fictional sample content used to capture screenshots of the real app. The botanical illustration was generated with the built-in OpenAI ImageGen tool; the exact prompt is recorded in `PROMPT.md`.

The illustration is a brand scene, not a screenshot or a claim that Framelet creates botanical paintings. The annotation screenshot and the three named finish examples in the README are actual app captures/exports.

Fraunces and DM Sans are bundled with their SIL Open Font licences. They come from the corresponding `ofl/` directories in the [Google Fonts repository](https://github.com/google/fonts). They are used for presentation artwork and are not installed as system fonts.

To render the cover and sample note locally, install the optional artwork tools `python`, `fontconfig` and `librsvg`, then run from the repository root:

```bash
python docs/launch/render.py
```

The script uses a fontconfig file scoped to its rendering process and stores cache files in `.build/`. It does not change the desktop's font configuration.
