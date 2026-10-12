#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
app_dir="$project_dir/build/On Air Companion.app"
guide_path="$project_dir/Resources/Beta-Install-Guide.txt"
release_dir="$project_dir/../releases"
app_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_dir/Contents/Info.plist")"
dmg_path="$release_dir/On-Air-Companion-$app_version-beta-macOS.dmg"

if [[ -e "$dmg_path" ]]; then
  print -u2 "Output already exists: $dmg_path"
  exit 1
fi

codesign --verify --deep --strict "$app_dir"
"$app_dir/Contents/MacOS/OnAirCompanion" --self-test

staging_dir="$(mktemp -d -t on-air-share)"
ditto "$app_dir" "$staging_dir/On Air Companion.app"
ln -s /Applications "$staging_dir/Applications"
cp "$guide_path" "$staging_dir/먼저 읽어 주세요.txt"
codesign --verify --deep --strict "$staging_dir/On Air Companion.app"

mkdir -p "$release_dir"
hdiutil create -volname "On Air Companion beta" -srcfolder "$staging_dir" -format UDZO "$dmg_path"
print "Packaged: $dmg_path"
print "Staging retained: $staging_dir"
