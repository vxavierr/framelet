# Credits and origins

Framelet builds on existing work. This page separates inherited code, product inspirations and the projects that support the app.

| Project | Contribution to Framelet |
| --- | --- |
| [Omaframe](https://github.com/btsouth/omaframe), by Tyler South (`btsouth`) | The direct source fork: version 0.7.4, commit `133da85819195573a597760d433bdcee85e4e824`, MIT. Capture, scrolling, recording, OCR, native annotations and the underlying studio/rendering work are inherited and extended. |
| [Omasnap](https://github.com/omacom/omasnap), copyright Tobi Lütke | Native Wayland capture code inherited through Omaframe, which identifies source commit `acfb3b5772ccb041b57ccc76e16f1b72719f37e9`. Its MIT notice is retained in [OMASNAP-LICENSE](native-src/docs/OMASNAP-LICENSE). |
| [Postcard](https://github.com/tahayvr/postcard), by `tahayvr` | A product reference for screenshot presentation, framing, composition and code cards. Framelet combines these ideas with its native capture flow. |
| [ShareX](https://github.com/ShareX/ShareX) | The original interaction goal: capture and annotate in place, with fast keyboard actions for copying and saving. |
| [MatteShot](https://github.com/btsouth/matteshot) and [Omaroll](https://github.com/btsouth/omaroll) | Workflow and style influences acknowledged by Omaframe. These are carried-forward upstream credits, rather than separate code imports into Framelet. |
| [Omarchy](https://github.com/omacom/omarchy) | The plugin platform, shell integration and theme conventions. |

The inline Framelet overlay integration, tapered brush, palettes, named finishes and original symbol are additions in this fork. The exact retained licences are in [LICENSE](LICENSE) and `native-src/`.

## Presentation assets

- The Framelet symbol is original artwork, distributed under MIT. Its editable source is in `design/`.
- [Fraunces](https://github.com/undercasetype/Fraunces) and [DM Sans](https://github.com/googlefonts/dm-fonts) are used in the launch artwork under the SIL Open Font License. The bundled notices are in `docs/launch/fonts/`.
- The botanical launch illustration was generated with OpenAI ImageGen. The exact prompt and editable cover are in `docs/launch/`.
- Interface screenshots and finish examples are actual native app captures/exports on fictional sample content. Study references used during symbol development are not distributed as Framelet assets.

## Runtime and development

The native application uses Qt, LayerShellQt and Wayland; the shell uses Quickshell on Hyprland. Clipboard support uses `wl-clipboard`. Optional features use Tesseract, `bat`, GPU Screen Recorder and FFmpeg. Required and optional dependencies are documented in the [README](README.md#install); their upstream projects retain their respective licences.
