#!/usr/bin/env python3
"""Apply Aporia's display name, original mark, launcher icon and dark splash to generated platforms."""
from pathlib import Path
import json
import re
import shutil

root = Path(__file__).resolve().parent.parent
brand = root / "assets" / "branding"
icons = brand / "launcher-icons"
label = "Aporia"
navy = "#0D092B"


def copy_if_exists(source: Path, destination: Path) -> bool:
    if source.exists() and destination.parent.exists():
        shutil.copy2(source, destination)
        return True
    return False


def apply_android() -> int:
    updated = 0
    manifest = root / "android/app/src/main/AndroidManifest.xml"
    if manifest.exists():
        text = manifest.read_text(encoding="utf-8")
        new, count = re.subn(r'android:label="[^"]*"', f'android:label="{label}"', text, count=1)
        if count:
            manifest.write_text(new, encoding="utf-8")
            updated += 1

    densities = {"mdpi": "mdpi", "hdpi": "hdpi", "xhdpi": "xhdpi", "xxhdpi": "xxhdpi", "xxxhdpi": "xxxhdpi"}
    res = root / "android/app/src/main/res"
    for density in densities:
        folder = res / f"mipmap-{density}"
        source = icons / f"ic_launcher_{density}.png"
        if copy_if_exists(source, folder / "ic_launcher.png"):
            updated += 1
        # Some generated templates/launchers also use a round variant.
        if (folder / "ic_launcher_round.png").exists() and copy_if_exists(source, folder / "ic_launcher_round.png"):
            updated += 1
        foreground_source = icons / f"ic_launcher_foreground_{density}.png"
        if copy_if_exists(foreground_source, folder / "ic_launcher_foreground.png"):
            updated += 1

    # Adaptive icon resources for Android 8+. These are generated alongside
    # the classic density icons so modern launchers show the same Aporia mark.
    if (res / "values").exists() and (res / "drawable").exists():
        colors = res / "values/aporia_colors.xml"
        colors.write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<resources><color name="aporia_launcher_background">#0D092B</color></resources>\n',
            encoding="utf-8",
        )
        updated += 1
        anydpi = res / "mipmap-anydpi-v26"
        anydpi.mkdir(parents=True, exist_ok=True)
        adaptive_xml = (
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/aporia_launcher_background" />\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
            '</adaptive-icon>\n'
        )
        (anydpi / "ic_launcher.xml").write_text(adaptive_xml, encoding="utf-8")
        (anydpi / "ic_launcher_round.xml").write_text(adaptive_xml, encoding="utf-8")
        updated += 2

    splash_source = brand / "aporia-mark-transparent-512.png"
    splash_target = res / "drawable-nodpi/aporia_splash_mark.png"
    if splash_source.exists() and (res / "drawable").exists():
        splash_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(splash_source, splash_target)
        splash = res / "drawable/launch_background.xml"
        splash.write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n'
            f'    <item android:drawable="{navy}" />\n'
            '    <item>\n'
            '        <bitmap android:gravity="center" android:src="@drawable/aporia_splash_mark" />\n'
            '    </item>\n'
            '</layer-list>\n',
            encoding="utf-8",
        )
        updated += 1

    return updated


def apply_web() -> int:
    updated = 0
    web = root / "web"
    if not web.exists():
        return 0
    index = web / "index.html"
    if index.exists():
        text = index.read_text(encoding="utf-8")
        text = re.sub(r'<title>.*?</title>', f'<title>{label}</title>', text, count=1, flags=re.DOTALL)
        text = text.replace('A new Flutter project.', 'Ideas worth thinking about. Aporia.')
        text = re.sub(r'(<meta[^>]+name="theme-color"[^>]+content=")[^"]*(")', rf'\g<1>{navy}\2', text, count=1)
        # Ensure a theme-color entry exists even when a Flutter template omits it.
        if 'name="theme-color"' not in text:
            text = text.replace('<head>', f'<head>\n  <meta name="theme-color" content="{navy}">', 1)
        # Avoid an abrupt white flash while Flutter's first frame is loading,
        # whether the generated template uses a CSS block or an inline style.
        text = re.sub(r'(background-color\s*:\s*)#[0-9a-fA-F]{3,8}', rf'\g<1>{navy}', text, flags=re.IGNORECASE)
        index.write_text(text, encoding="utf-8")
        updated += 1

    manifest = web / "manifest.json"
    if manifest.exists():
        data = json.loads(manifest.read_text(encoding="utf-8"))
        data["name"] = label
        data["short_name"] = label
        data["description"] = "A community for sharing reflections and ideas."
        data["background_color"] = navy
        data["theme_color"] = navy
        manifest.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        updated += 1

    web_icon_map = {
        "Icon-192.png": "Icon-192.png",
        "Icon-512.png": "Icon-512.png",
        "Icon-maskable-192.png": "Icon-maskable-192.png",
        "Icon-maskable-512.png": "Icon-maskable-512.png",
    }
    for name, source_name in web_icon_map.items():
        if copy_if_exists(icons / source_name, web / "icons" / name):
            updated += 1
    if copy_if_exists(icons / "favicon.png", web / "favicon.png"):
        updated += 1
    return updated


def apply_ios_if_generated() -> int:
    """Prepare an existing generated iOS icon catalog, if the project has one."""
    catalog = root / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = catalog / "Contents.json"
    info = root / "ios/Runner/Info.plist"
    updated = 0
    if info.exists():
        text = info.read_text(encoding="utf-8")
        for key in ("CFBundleDisplayName", "CFBundleName"):
            text, count = re.subn(
                rf'(<key>{key}</key>\s*<string>).*?(</string>)',
                rf'\g<1>{label}\g<2>', text, count=1, flags=re.DOTALL,
            )
            updated += count
        info.write_text(text, encoding="utf-8")
    if contents.exists():
        try:
            data = json.loads(contents.read_text(encoding="utf-8"))
            for item in data.get("images", []):
                filename = item.get("filename")
                dimensions = item.get("size", "").split("x")
                scale = int(item.get("scale", "1x").replace("x", "") or "1")
                if not filename or not dimensions:
                    continue
                try:
                    pixels = round(float(dimensions[0]) * scale)
                except ValueError:
                    continue
                source = icons / f"ios-{pixels}.png"
                if copy_if_exists(source, catalog / filename):
                    updated += 1
        except (OSError, json.JSONDecodeError) as error:
            raise SystemExit(f"Could not update iOS icon catalog: {error}")
    return updated


count = apply_android() + apply_web() + apply_ios_if_generated()
print(f"Aporia branding applied to {count} generated platform file(s) where present.")
print("This script changes local platform assets/display names only; it does not alter Supabase or database data.")
