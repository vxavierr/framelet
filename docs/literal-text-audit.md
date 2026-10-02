# Literal display text, 0.3.2

The marketplace review at 0bad6d7 identified AutoText in the hidden annotation measurement item in MarkCanvas.qml. This was a static finding, not a confirmed incident.

All native QML Text items now explicitly use PlainText. There are no intentional RichText or StyledText display items in this UI. This includes the annotation measurement, image and video names, saved output names and paths, draft names, preset names, messages, and shared button/choice/caption components. Static labels use the same policy so future dynamic bindings inherit it. Status, palette-name and shared-button tooltips use LiteralToolTip with a PlainText content item. The remaining attached tooltips contain static time-control hints. TextEdit, TextArea, TextField and the code highlighting implementation are unchanged. Annotation export uses QPainter::drawText, which already draws literal strings.

The literal-text suite checks every native QML Text declaration and instantiates the actual measurement declaration with synthetic HTML-like annotations and file names. It checks literal strings, PlainText format and nonzero measurement. A test network manager counts and refuses any request before it reaches a transport. No external image is fetched by the regression test.

This change addresses display text interpretation. It does not claim to sandbox the entire native application or complete the marketplace's review.
