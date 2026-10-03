#!/usr/bin/env python3
"""Inspect every ZIP member's raw bytes, including all Mach-O architectures."""
import re
import sys
import zipfile

PATTERNS = {
    "local build path": rb"/(?:Users|home)/[A-Za-z0-9_.-]+/",
    "private key": rb"-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----",
    "access token": rb"(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{24,})",
}
ALLOWED = {
    "WiFi Location Switcher.app/Contents/Info.plist",
    "WiFi Location Switcher.app/Contents/MacOS/WiFiLocationSwitcher",
    "WiFi Location Switcher.app/Contents/Resources/AppIcon.icns",
    "WiFi Location Switcher.app/Contents/_CodeSignature/CodeResources",
}


def audit(path):
    findings = []
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            findings.append("Archive integrity check failed")
        files = {entry.filename for entry in archive.infolist() if not entry.is_dir()}
        if files != ALLOWED:
            findings.append("Archive contains missing or unexpected files")
        for entry in archive.infolist():
            if entry.is_dir():
                continue
            data = archive.read(entry)
            for description, pattern in PATTERNS.items():
                if re.search(pattern, data):
                    findings.append(f"{entry.filename}: {description}")
    return findings


if __name__ == "__main__":
    findings = audit(sys.argv[1])
    if findings:
        print("Release privacy audit failed:\n" + "\n".join(findings), file=sys.stderr)
        sys.exit(1)
    print("Release privacy audit passed: expected files only; no build paths or known credential patterns.")
