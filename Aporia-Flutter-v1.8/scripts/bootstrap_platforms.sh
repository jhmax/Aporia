#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found. Install the Flutter SDK and add 'flutter' to PATH." >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is required to set generated Android/Web display names." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BACKUP="$(mktemp -d)"
cleanup() { rm -rf "$BACKUP"; }
trap cleanup EXIT

for file in pubspec.yaml analysis_options.yaml .gitignore README.md lib/main.dart test/widget_test.dart; do
  cp "$file" "$BACKUP/$(echo "$file" | tr '/' '_')"
done

flutter create --platforms=android,web --org com.entrelinhas --project-name entrelinhas .

for file in pubspec.yaml analysis_options.yaml .gitignore README.md lib/main.dart test/widget_test.dart; do
  cp "$BACKUP/$(echo "$file" | tr '/' '_')" "$file"
done

python3 scripts/set_app_display_name.py
flutter pub get
printf '\nAporia Android and Web platforms generated with the Aporia brand. Run flutter analyze and flutter test next.\n'
