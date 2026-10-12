#!/bin/zsh
set -euo pipefail

# Prepare a separate release copy. Never alter the running or installed app.
# Authentication is read from a user-created Keychain profile, never from files.
project_dir="${0:A:h:h}"
app_dir="$project_dir/build/On Air Companion.app"
release_dir="$project_dir/../releases"
identity="${OAC_SIGNING_IDENTITY:-}"
profile="${OAC_NOTARY_PROFILE:-}"
wait_timeout="${OAC_NOTARY_WAIT_TIMEOUT:-30m}"
mode="${1:---check}"
work_dir=""

die() { print -u2 -- "$1"; exit 2; }

if [[ "$mode" != "--check" && "$mode" != "--run" ]]; then
  die "Usage: zsh scripts/sign-and-notarize.sh --check|--run"
fi

for tool in codesign security ditto hdiutil plutil xcrun; do
  command -v "$tool" >/dev/null || die "Missing tool: $tool"
done
xcrun --find notarytool >/dev/null
xcrun --find stapler >/dev/null
[[ -d "$app_dir" ]] || die "Build the app first with scripts/build-app.sh."

# This app has one executable. Nested code must be signed inside-out separately.
for directory in Frameworks PlugIns XPCServices; do
  [[ ! -d "$app_dir/Contents/$directory" ]] || die "Nested code detected. Review signing order before continuing."
done

valid_identities="$(security find-identity -v -p codesigning)"
if ! print -r -- "$valid_identities" | grep -F 'Developer ID Application:' >/dev/null; then
  die "BLOCKED: No valid Developer ID Application certificate with a private key. Complete enrollment and certificate setup first."
fi
if [[ -z "$identity" ]]; then
  print -r -- "$valid_identities" | grep -F 'Developer ID Application:'
  die "Set OAC_SIGNING_IDENTITY to the exact Developer ID Application name."
fi
[[ "$identity" == 'Developer ID Application:'* ]] || die "Use a Developer ID Application identity, not a development or App Store certificate."
print -r -- "$valid_identities" | grep -F -- "\"$identity\"" >/dev/null || die "The selected identity is unavailable or invalid."
[[ -n "$profile" ]] || die "Set OAC_NOTARY_PROFILE to the profile saved by notarytool store-credentials."

codesign --verify --deep --strict "$app_dir"
app_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_dir/Contents/Info.plist")"
[[ "$app_version" == <->.<->.<-> ]] || die "Unexpected version format."
final_dmg="$release_dir/On-Air-Companion-$app_version-notarized-macOS.dmg"
[[ ! -e "$final_dmg" ]] || die "Release already exists; choose a new version instead of overwriting it."

print "Local prerequisites available. Credentials are validated by Apple on submission."
if [[ "$mode" == "--check" ]]; then
  print "No signatures, uploads, or installed-app changes were made."
  exit 0
fi

mkdir -p "$project_dir/build"
work_dir="$(mktemp -d "$project_dir/build/notarization.XXXXXX")"
print "Private staging: $work_dir"

TRAPZERR() {
  print -u2 "Stopped. Staging and any Apple submission IDs remain at $work_dir."
  print -u2 "Reuse an existing submission ID after a timeout; do not submit the same archive again."
}

signed_app="$work_dir/On Air Companion.app"
ditto "$app_dir" "$signed_app"
codesign --force --options runtime --timestamp --sign "$identity" "$signed_app"
codesign --verify --deep --strict --verbose=2 "$signed_app"
"$signed_app/Contents/MacOS/OnAirCompanion" --self-test

submit_and_wait() {
  local payload="$1"
  local record="$2"
  local submission_id
  local result_status

  # Save the submission ID immediately so a network timeout never loses it.
  xcrun notarytool submit "$payload" --keychain-profile "$profile" --output-format json > "$record"
  submission_id="$(plutil -extract id raw -o - "$record")"
  print "Apple submission: $submission_id"

  if ! xcrun notarytool wait "$submission_id" --keychain-profile "$profile" --timeout "$wait_timeout" --output-format json > "$record.wait.json"; then
    print -u2 "Apple processing did not finish successfully. Read the saved submission ID in $record before retrying."
    return 1
  fi
  result_status="$(plutil -extract status raw -o - "$record.wait.json")"
  if [[ "$result_status" != "Accepted" ]]; then
    xcrun notarytool log "$submission_id" --keychain-profile "$profile" "$record.apple-log.json" || true
    print -u2 "Apple status: $result_status. This output must not be released."
    return 1
  fi
}

app_zip="$work_dir/app-for-notarization.zip"
ditto -c -k --sequesterRsrc --keepParent "$signed_app" "$app_zip"
submit_and_wait "$app_zip" "$work_dir/app-submission.json"
xcrun stapler staple "$signed_app"
xcrun stapler validate "$signed_app"
codesign --verify --deep --strict --verbose=2 "$signed_app"
if command -v syspolicy_check >/dev/null; then
  syspolicy_check distribution "$signed_app"
else
  spctl --assess --type execute --verbose=2 "$signed_app"
fi

dmg_root="$work_dir/dmg-root"
mkdir -p "$dmg_root"
ditto "$signed_app" "$dmg_root/On Air Companion.app"
ln -s /Applications "$dmg_root/Applications"
cp "$project_dir/Resources/Install-Guide.txt" "$dmg_root/먼저 읽어 주세요.txt"
candidate_dmg="$work_dir/On-Air-Companion-$app_version-macOS.dmg"
hdiutil create -volname "On Air Companion" -srcfolder "$dmg_root" -format UDZO "$candidate_dmg"
codesign --timestamp --sign "$identity" "$candidate_dmg"
submit_and_wait "$candidate_dmg" "$work_dir/dmg-submission.json"
xcrun stapler staple "$candidate_dmg"
xcrun stapler validate "$candidate_dmg"
hdiutil verify "$candidate_dmg"
codesign --verify --strict "$candidate_dmg"

# A distributable filename is created only after both Apple checks succeeded.
mkdir -p "$release_dir"
cp "$candidate_dmg" "$final_dmg"
shasum -a 256 "$final_dmg"
print "Signed and notarized release prepared: $final_dmg"
print "Test a fresh download on another Mac before publishing."
