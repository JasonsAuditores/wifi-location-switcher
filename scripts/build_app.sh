#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
requested_version=${APP_VERSION:-1.0.0}
version=${requested_version#v}
build_number=${BUILD_NUMBER:-1}
signing_identity=${CODE_SIGN_IDENTITY:--}
dist_dir="$project_dir/dist"
app_name="WiFi Location Switcher"
app_path="$dist_dir/$app_name.app"

cd "$project_dir"
/usr/bin/swift build -c release --arch arm64 --product WiFiLocationSwitcher
arm_binary_dir=$(/usr/bin/swift build -c release --arch arm64 --show-bin-path)
/usr/bin/swift build -c release --arch x86_64 --product WiFiLocationSwitcher
intel_binary_dir=$(/usr/bin/swift build -c release --arch x86_64 --show-bin-path)

/bin/rm -rf "$app_path"
/bin/mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
/usr/bin/lipo -create \
    "$arm_binary_dir/WiFiLocationSwitcher" \
    "$intel_binary_dir/WiFiLocationSwitcher" \
    -output "$app_path/Contents/MacOS/WiFiLocationSwitcher"
/bin/chmod 755 "$app_path/Contents/MacOS/WiFiLocationSwitcher"
# Remove debug symbols, including source and object file paths, from both slices.
/usr/bin/strip -S "$app_path/Contents/MacOS/WiFiLocationSwitcher"
/usr/bin/sed \
    -e "s/__VERSION__/$version/g" \
    -e "s/__BUILD_NUMBER__/$build_number/g" \
    "$project_dir/App/Info.plist" > "$app_path/Contents/Info.plist"

iconset_path="$dist_dir/AppIcon.iconset"
/bin/rm -rf "$iconset_path"
/bin/mkdir -p "$iconset_path"
for size in 16 32 128 256 512; do
    /usr/bin/sips -z "$size" "$size" "$project_dir/App/AppIcon-1024.png" \
        --out "$iconset_path/icon_${size}x${size}.png" >/dev/null
    double_size=$((size * 2))
    /usr/bin/sips -z "$double_size" "$double_size" "$project_dir/App/AppIcon-1024.png" \
        --out "$iconset_path/icon_${size}x${size}@2x.png" >/dev/null
done
/usr/bin/iconutil -c icns "$iconset_path" -o "$app_path/Contents/Resources/AppIcon.icns"
/bin/rm -rf "$iconset_path"

if [[ "$signing_identity" == "-" ]]; then
    /usr/bin/codesign --force --deep --sign - "$app_path"
else
    /usr/bin/codesign --force --deep --options runtime --timestamp --sign "$signing_identity" "$app_path"
fi

/usr/bin/codesign --verify --deep --strict --verbose=2 "$app_path"
/usr/bin/plutil -lint "$app_path/Contents/Info.plist"

archive_path="$dist_dir/WiFi-Location-Switcher-$version.zip"
/bin/rm -f "$archive_path"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app_path" "$archive_path"
/usr/bin/python3 "$script_dir/audit_release.py" "$archive_path"

echo "Built: $app_path"
echo "Archive: $archive_path"
