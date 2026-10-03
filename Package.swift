// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WiFiLocationSwitcher",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SwitcherCore", targets: ["SwitcherCore"]),
        .executable(name: "WiFiLocationSwitcher", targets: ["WiFiLocationSwitcher"])
    ],
    targets: [
        .target(name: "SwitcherCore"),
        .executableTarget(
            name: "WiFiLocationSwitcher",
            dependencies: ["SwitcherCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("CoreWLAN"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .executableTarget(name: "SwitcherCoreSelfTest", dependencies: ["SwitcherCore"])
    ]
)
