import AppKit
import Combine
import CoreLocation
import CoreWLAN
import Foundation
import ServiceManagement
import SwitcherCore

@MainActor
final class AppController: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var settings: SwitcherSettings {
        didSet {
            persistSettings()
            resetObservation()
        }
    }
    @Published private(set) var availableLocations: [String] = []
    @Published private(set) var currentSSID: String?
    @Published private(set) var currentLocation: String?
    @Published private(set) var lastMessage = "Ready"
    @Published private(set) var lastMessageIsError = false
    @Published private(set) var permissionStatus: CLAuthorizationStatus
    @Published private(set) var loginItemStatus: SMAppService.Status = .notRegistered

    private let locationManager = CLLocationManager()
    private let wifiClient = CWWiFiClient.shared()
    private let settingsKey = "SwitcherSettings.v1"
    private var timer: Timer?
    private var lastObservedSSID: String?
    private var observationCount = 0
    private var cooldownUntil = Date.distantPast
    private var locationRefreshCounter = 0

    override init() {
        settings = Self.loadSettings(key: "SwitcherSettings.v1")
        permissionStatus = CLLocationManager().authorizationStatus
        super.init()
        locationManager.delegate = self
        permissionStatus = locationManager.authorizationStatus
        refreshAll()
        startMonitoring()
    }

    var permissionGranted: Bool {
        permissionStatus == .authorized || permissionStatus == .authorizedAlways
    }

    var permissionDescription: String {
        switch permissionStatus {
        case .authorized, .authorizedAlways:
            return "Wi-Fi access allowed"
        case .notDetermined:
            return "Wi-Fi access needs permission"
        case .denied:
            return "Wi-Fi access was denied"
        case .restricted:
            return "Wi-Fi access is restricted"
        @unknown default:
            return "Unknown permission status"
        }
    }

    var loginItemEnabled: Bool {
        loginItemStatus == .enabled || loginItemStatus == .requiresApproval
    }

    var loginItemDescription: String {
        switch loginItemStatus {
        case .enabled:
            return "Starts automatically after login"
        case .requiresApproval:
            return "Needs approval in System Settings"
        case .notRegistered:
            return "Does not start automatically"
        case .notFound:
            return "Move the app to Applications first"
        @unknown default:
            return "Unknown login item status"
        }
    }

    var validationMessages: [String] {
        SwitchDecision.validationMessages(for: settings, availableLocations: availableLocations)
    }

    func requestPermission() {
        if permissionStatus == .denied || permissionStatus == .restricted {
            openLocationSettings()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.permissionStatus = status
            self.refreshStatus()
        }
    }

    func refreshAll() {
        availableLocations = NetworkSetup.locations()
        refreshStatus()
        refreshLoginItemStatus()
    }

    func refreshStatus() {
        currentLocation = NetworkSetup.currentLocation()
        currentSSID = permissionGranted ? wifiClient.interface()?.ssid() : nil
    }

    func addRule(usingCurrentSSID: Bool = false) {
        let ssid = usingCurrentSSID ? (currentSSID ?? "") : ""
        if !ssid.isEmpty, settings.rules.contains(where: { $0.ssid == ssid }) {
            setMessage("A rule for \(ssid) already exists", isError: true)
            return
        }
        settings.rules.append(NetworkRule(ssid: ssid, location: currentLocation ?? availableLocations.first ?? ""))
    }

    func removeRule(id: UUID) {
        settings.rules.removeAll { $0.id == id }
    }

    func setLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshLoginItemStatus()
            setMessage(enabled ? "Launch at login enabled" : "Launch at login disabled")
        } catch {
            refreshLoginItemStatus()
            setMessage("Could not change login setting: \(error.localizedDescription)", isError: true)
        }
    }

    func openLoginItemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func openLocationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") else { return }
        NSWorkspace.shared.open(url)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.monitorTick()
            }
        }
    }

    private func monitorTick() {
        guard settings.switchingEnabled, permissionGranted, Date() >= cooldownUntil else { return }

        let ssid = wifiClient.interface()?.ssid()
        currentSSID = ssid
        locationRefreshCounter += 1
        if locationRefreshCounter >= 12 {
            locationRefreshCounter = 0
            availableLocations = NetworkSetup.locations()
        }

        if ssid == lastObservedSSID {
            observationCount += 1
        } else {
            lastObservedSSID = ssid
            observationCount = 1
        }

        // A location switch can briefly disconnect Wi-Fi. Never react to that transient gap.
        guard ssid != nil, observationCount >= 2 else { return }
        guard let desired = SwitchDecision.desiredLocation(for: ssid, settings: settings) else { return }

        let existing = NetworkSetup.currentLocation()
        currentLocation = existing
        guard existing != desired else { return }
        guard availableLocations.contains(desired) else {
            setMessage("Network location \"\(desired)\" no longer exists", isError: true)
            return
        }

        let result = NetworkSetup.switchLocation(to: desired)
        if result.success {
            currentLocation = desired
            cooldownUntil = Date().addingTimeInterval(20)
            resetObservation()
            setMessage("Switched to \(desired) for \(ssid ?? "Wi-Fi")")
        } else {
            setMessage(result.message, isError: true)
        }
    }

    private func resetObservation() {
        lastObservedSSID = nil
        observationCount = 0
    }

    private func persistSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
        } catch {
            setMessage("Could not save settings", isError: true)
        }
    }

    private static func loadSettings(key: String) -> SwitcherSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(SwitcherSettings.self, from: data) else {
            return SwitcherSettings()
        }
        return decoded
    }

    private func refreshLoginItemStatus() {
        loginItemStatus = SMAppService.mainApp.status
    }

    private func setMessage(_ message: String, isError: Bool = false) {
        lastMessage = message
        lastMessageIsError = isError
    }
}

private enum NetworkSetup {
    struct Result {
        let success: Bool
        let message: String
    }

    static func locations() -> [String] {
        let result = run(["-listlocations"])
        return result.success ? NetworkSetupOutputParser.locations(from: result.message) : []
    }

    static func currentLocation() -> String? {
        let result = run(["-getcurrentlocation"])
        return result.success ? NetworkSetupOutputParser.singleValue(from: result.message) : nil
    }

    static func switchLocation(to location: String) -> Result {
        run(["-switchtolocation", location])
    }

    private static func run(_ arguments: [String]) -> Result {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: data, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return Result(
                success: process.terminationStatus == 0,
                message: output.isEmpty ? (process.terminationStatus == 0 ? "OK" : "networksetup failed") : output
            )
        } catch {
            return Result(success: false, message: error.localizedDescription)
        }
    }
}
