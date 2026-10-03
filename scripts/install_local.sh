#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
source_app="$project_dir/dist/WiFi Location Switcher.app"
destination_dir="/Applications"
destination_app="$destination_dir/WiFi Location Switcher.app"

if [[ ! -d "$source_app" ]]; then
    echo "Build the app first with scripts/build_app.sh"
    exit 1
fi

/usr/bin/ditto "$source_app" "$destination_app"
/usr/bin/open "$destination_app"
echo "Installed: $destination_app"
