#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
app_dir="$project_dir/build/On Air Companion.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
module_cache_dir="$project_dir/build/ModuleCache"
icon_path="$project_dir/Resources/AppIcon.icns"

mkdir -p "$macos_dir" "$module_cache_dir"

if [[ ! -f "$icon_path" || "$project_dir/scripts/generate-app-icon.swift" -nt "$icon_path" ]]; then
  icon_work_dir="$(mktemp -d)"
  iconset_dir="$icon_work_dir/AppIcon.iconset"
  source_icon="$icon_work_dir/AppIcon-1024.png"
  mkdir -p "$iconset_dir"

  swift "$project_dir/scripts/generate-app-icon.swift" "$source_icon"
  sips -z 16 16 "$source_icon" --out "$iconset_dir/icon_16x16.png" >/dev/null
  sips -z 32 32 "$source_icon" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$source_icon" --out "$iconset_dir/icon_32x32.png" >/dev/null
  sips -z 64 64 "$source_icon" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$source_icon" --out "$iconset_dir/icon_128x128.png" >/dev/null
  sips -z 256 256 "$source_icon" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$source_icon" --out "$iconset_dir/icon_256x256.png" >/dev/null
  sips -z 512 512 "$source_icon" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$source_icon" --out "$iconset_dir/icon_512x512.png" >/dev/null
  cp "$source_icon" "$iconset_dir/icon_512x512@2x.png"
  iconutil -c icns "$iconset_dir" -o "$icon_path"
  rm -rf "$icon_work_dir"
fi

swiftc \
  -O \
  -framework AppKit \
  -framework ApplicationServices \
  -framework QuartzCore \
  -module-cache-path "$module_cache_dir" \
  "$project_dir/Sources/main.swift" \
  -o "$macos_dir/OnAirCompanion"

cp "$project_dir/Resources/Info.plist" "$contents_dir/Info.plist"
mkdir -p "$contents_dir/Resources"
cp "$icon_path" "$contents_dir/Resources/AppIcon.icns"
characters_dir="$contents_dir/Resources/Characters"
rm -rf "$characters_dir"
mkdir -p "$characters_dir"
cp "$project_dir/Resources/Characters/"*.png "$characters_dir/"
active_characters_dir="$contents_dir/Resources/CharactersActive"
rm -rf "$active_characters_dir"
mkdir -p "$active_characters_dir"
cp "$project_dir/Resources/CharactersActive/"*.png "$active_characters_dir/"
codesign --force --deep --sign - "$app_dir"

echo "$app_dir"
