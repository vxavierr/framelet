#!/usr/bin/env python3
"""Render the launch artwork with project-local fonts, without installing them."""
from pathlib import Path
import os
import subprocess

root = Path(__file__).resolve().parents[2]
launch = root / "docs/launch"
cache = root / ".build/launch-fonts"
cache.mkdir(parents=True, exist_ok=True)
config = cache / "fonts.conf"
config.write_text(f'''<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
  <dir>{launch / 'fonts/fraunces'}</dir>
  <dir>{launch / 'fonts/dm-sans'}</dir>
  <cachedir>{cache}</cachedir>
</fontconfig>
''')
env = dict(os.environ, FONTCONFIG_FILE=str(config), TMPDIR=str(cache))
for source, output in [
    (launch / "cover.svg", root / "preview.png"),
    (launch / "demo.svg", root / "docs/media/sample-note.png"),
]:
    subprocess.run(["rsvg-convert", "-o", str(output), str(source)], env=env, check=True)
    print(output.relative_to(root))
