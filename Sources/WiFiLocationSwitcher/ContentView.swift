import SwiftUI
import SwitcherCore

struct ContentView: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    statusSection
                    rulesSection
                    fallbackSection
                    startupSection
                    if !controller.validationMessages.isEmpty {
                        warningSection
                    }
                }
                .padding(18)
            }
            Divider()
            footer
        }
        .frame(width: 560, height: 640)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.router.fill")
                .font(.system(size: 28))
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("WiFi Location Switcher")
                    .font(.headline)
                Text("Switch macOS network locations by Wi-Fi name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $controller.settings.switchingEnabled)
                .labelsHidden()
                .help("Enable automatic switching")
        }
        .padding(18)
    }

    private var statusSection: some View {
        GroupBox("Current status") {
            VStack(spacing: 10) {
                statusRow("Wi-Fi", controller.currentSSID ?? "Not available")
                statusRow("Network location", controller.currentLocation ?? "Not available")
                HStack {
                    Circle()
                        .fill(controller.permissionGranted ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(controller.permissionDescription)
                        .font(.caption)
                    Spacer()
                    if !controller.permissionGranted {
                        Button(controller.permissionStatus == .notDetermined ? "Allow" : "Open Settings") {
                            controller.requestPermission()
                        }
                        .controlSize(.small)
                    }
                    Button {
                        controller.refreshAll()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh")
                }
            }
            .padding(.top, 5)
        }
    }

    private var rulesSection: some View {
        GroupBox("Rules") {
            VStack(spacing: 10) {
                if controller.settings.rules.isEmpty {
                    Text("Add a rule such as Home Wi-Fi → Home location.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }

                ForEach($controller.settings.rules) { $rule in
                    HStack(spacing: 8) {
                        TextField("Wi-Fi name (SSID)", text: $rule.ssid)
                            .textFieldStyle(.roundedBorder)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                        locationPicker(selection: $rule.location)
                        Button(role: .destructive) {
                            controller.removeRule(id: rule.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                HStack {
                    Button {
                        controller.addRule()
                    } label: {
                        Label("Add rule", systemImage: "plus")
                    }
                    if controller.currentSSID != nil {
                        Button("Add current Wi-Fi") {
                            controller.addRule(usingCurrentSSID: true)
                        }
                    }
                    Spacer()
                }
                .controlSize(.small)
            }
            .padding(.top, 5)
        }
    }

    private var fallbackSection: some View {
        GroupBox("When no rule matches") {
            HStack {
                Text("Use network location")
                Spacer()
                Picker("", selection: Binding(
                    get: { controller.settings.fallbackLocation ?? "" },
                    set: { controller.settings.fallbackLocation = $0.isEmpty ? nil : $0 }
                )) {
                    Text("Do nothing").tag("")
                    ForEach(controller.availableLocations, id: \.self) { location in
                        Text(location).tag(location)
                    }
                }
                .labelsHidden()
                .frame(width: 220)
            }
            .padding(.top, 5)
        }
    }

    private var startupSection: some View {
        GroupBox("Startup") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Launch after login", isOn: Binding(
                    get: { controller.loginItemEnabled },
                    set: { controller.setLoginItem(enabled: $0) }
                ))
                Text(controller.loginItemDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if controller.loginItemStatus == .requiresApproval {
                    Button("Open Login Items Settings") {
                        controller.openLoginItemSettings()
                    }
                    .controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 5)
        }
    }

    private var warningSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(controller.validationMessages, id: \.self) { message in
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        HStack {
            Circle()
                .fill(controller.lastMessageIsError ? Color.red : Color.green)
                .frame(width: 7, height: 7)
            Text(controller.lastMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Button("Quit") {
                controller.quit()
            }
            .controlSize(.small)
        }
        .padding(12)
    }

    private func statusRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .textSelection(.enabled)
        }
    }

    private func locationPicker(selection: Binding<String>) -> some View {
        Picker("Location", selection: selection) {
            if controller.availableLocations.isEmpty {
                Text("No locations found").tag("")
            } else {
                ForEach(controller.availableLocations, id: \.self) { location in
                    Text(location).tag(location)
                }
            }
        }
        .labelsHidden()
        .frame(width: 170)
    }
}
