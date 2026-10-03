import SwiftUI

@main
struct WiFiLocationSwitcherApp: App {
    @StateObject private var controller = AppController()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(controller)
        } label: {
            Image(systemName: controller.settings.switchingEnabled ? "wifi.router.fill" : "wifi.router")
                .accessibilityLabel("WiFi Location Switcher")
        }
        .menuBarExtraStyle(.window)
    }
}
