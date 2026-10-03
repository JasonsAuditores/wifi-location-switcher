import Foundation

public struct NetworkRule: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var ssid: String
    public var location: String

    public init(id: UUID = UUID(), ssid: String = "", location: String = "") {
        self.id = id
        self.ssid = ssid
        self.location = location
    }
}

public struct SwitcherSettings: Codable, Equatable, Sendable {
    public var rules: [NetworkRule]
    public var fallbackLocation: String?
    public var switchingEnabled: Bool

    public init(
        rules: [NetworkRule] = [],
        fallbackLocation: String? = nil,
        switchingEnabled: Bool = true
    ) {
        self.rules = rules
        self.fallbackLocation = fallbackLocation
        self.switchingEnabled = switchingEnabled
    }
}

public enum SwitchDecision {
    public static func desiredLocation(for ssid: String?, settings: SwitcherSettings) -> String? {
        guard settings.switchingEnabled, let ssid else { return nil }

        if let match = settings.rules.first(where: {
            !$0.ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !$0.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.ssid == ssid
        }) {
            return match.location
        }

        guard let fallback = settings.fallbackLocation,
              !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return fallback
    }

    public static func validationMessages(
        for settings: SwitcherSettings,
        availableLocations: [String]
    ) -> [String] {
        var messages: [String] = []
        let completedRules = settings.rules.filter {
            !$0.ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !$0.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        let duplicateSSIDs = Dictionary(grouping: completedRules, by: \.ssid)
            .filter { $0.value.count > 1 }
            .keys
            .sorted()
        if !duplicateSSIDs.isEmpty {
            messages.append("Duplicate SSIDs: \(duplicateSSIDs.joined(separator: ", "))")
        }

        let missingLocations = Set(completedRules.map(\.location))
            .subtracting(availableLocations)
            .sorted()
        if !missingLocations.isEmpty {
            messages.append("Missing network locations: \(missingLocations.joined(separator: ", "))")
        }

        if let fallback = settings.fallbackLocation,
           !fallback.isEmpty,
           !availableLocations.contains(fallback) {
            messages.append("Missing fallback location: \(fallback)")
        }
        return messages
    }
}

public enum NetworkSetupOutputParser {
    public static func locations(from output: String) -> [String] {
        output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    public static func singleValue(from output: String) -> String? {
        let value = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
