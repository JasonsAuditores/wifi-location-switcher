import Foundation
import SwitcherCore

private func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAILED: \(message)\n", stderr)
        exit(1)
    }
}

let configured = SwitcherSettings(
    rules: [NetworkRule(ssid: "Home WiFi", location: "Home")],
    fallbackLocation: "Automatic"
)
check(
    SwitchDecision.desiredLocation(for: "Home WiFi", settings: configured) == "Home",
    "matching rule should win"
)
check(
    SwitchDecision.desiredLocation(for: "Cafe", settings: configured) == "Automatic",
    "fallback should handle unmatched Wi-Fi"
)
check(
    SwitchDecision.desiredLocation(for: nil, settings: configured) == nil,
    "a disconnected Mac should not switch"
)

var disabled = configured
disabled.switchingEnabled = false
check(
    SwitchDecision.desiredLocation(for: "Home WiFi", settings: disabled) == nil,
    "disabled switching should not act"
)

check(
    NetworkSetupOutputParser.locations(from: "Automatic\nHome Office\n\n")
        == ["Automatic", "Home Office"],
    "location output should parse"
)
check(
    NetworkSetupOutputParser.singleValue(from: " Home \n") == "Home",
    "single output should trim whitespace"
)

let invalid = SwitcherSettings(
    rules: [
        NetworkRule(ssid: "Home WiFi", location: "Home"),
        NetworkRule(ssid: "Home WiFi", location: "Removed")
    ],
    fallbackLocation: "Automatic"
)
check(
    SwitchDecision.validationMessages(
        for: invalid,
        availableLocations: ["Automatic", "Home"]
    ).count == 2,
    "validation should find duplicates and missing locations"
)

do {
    let data = try JSONEncoder().encode(configured)
    let decoded = try JSONDecoder().decode(SwitcherSettings.self, from: data)
    check(decoded == configured, "settings should save and load without changes")
} catch {
    fputs("FAILED: settings round-trip threw \(error)\n", stderr)
    exit(1)
}

print("All SwitcherCore checks passed.")
