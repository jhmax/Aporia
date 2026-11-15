#!/usr/bin/env python3
"""Set the Aporia display name in generated Flutter platform files."""
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parent.parent
label = "Aporia"

android_manifest = root / "android/app/src/main/AndroidManifest.xml"
if android_manifest.exists():
    content = android_manifest.read_text(encoding="utf-8")
    updated, count = re.subn(r'android:label="[^"]*"', f'android:label="{label}"', content, count=1)
    if count:
        android_manifest.write_text(updated, encoding="utf-8")

web_index = root / "web/index.html"
if web_index.exists():
    content = web_index.read_text(encoding="utf-8")
    content = re.sub(r'<title>.*?</title>', f'<title>{label}</title>', content, count=1, flags=re.DOTALL)
    # Improve the generated description where Flutter's default placeholder exists.
    content = content.replace('A new Flutter project.', 'Uma comunidade para partilhar reflexões.')
    web_index.write_text(content, encoding="utf-8")

web_manifest = root / "web/manifest.json"
if web_manifest.exists():
    try:
        manifest = json.loads(web_manifest.read_text(encoding="utf-8"))
        manifest["name"] = label
        manifest["short_name"] = "Aporia"
        if "description" in manifest:
            manifest["description"] = "Uma comunidade para partilhar reflexões."
        web_manifest.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    except (json.JSONDecodeError, OSError) as error:
        raise SystemExit(f"Could not update web/manifest.json: {error}")

# If iOS platform files are generated on a later Mac, apply the display name there too.
ios_plist = root / "ios/Runner/Info.plist"
if ios_plist.exists():
    content = ios_plist.read_text(encoding="utf-8")
    for key in ("CFBundleDisplayName", "CFBundleName"):
        content = re.sub(
            rf'(<key>{key}</key>\s*<string>).*?(</string>)',
            rf'\g<1>{label}\g<2>',
            content,
            count=1,
            flags=re.DOTALL,
        )
    ios_plist.write_text(content, encoding="utf-8")

print("Aporia display names applied where generated platform files were found.")
