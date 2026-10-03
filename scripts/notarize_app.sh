#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
version=${APP_VERSION:-1.0.0}
profile=${NOTARY_PROFILE:?Set NOTARY_PROFILE to a notarytool keychain profile name}
app_path="$project_dir/dist/WiFi Location Switcher.app"
archive_path="$project_dir/dist/WiFi-Location-Switcher-$version.zip"

if [[ ! -d "$app_path" ]]; then
    echo "Build the app before notarizing it."
    exit 1
fi

/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app_path" "$archive_path"
/usr/bin/xcrun notarytool submit "$archive_path" --keychain-profile "$profile" --wait
/usr/bin/xcrun stapler staple "$app_path"
/bin/rm -f "$archive_path"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app_path" "$archive_path"

echo "Notarized: $archive_path"
