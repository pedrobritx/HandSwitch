//
//  AppDelegate.swift
//  HandSwitch
//
//  Configures the app as a menu-bar accessory and owns the status item.
//

import AppKit

/// The application delegate: sets the accessory activation policy, starts the
/// object graph, and creates the menu-bar status item.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let environment = AppEnvironment.shared
    private var statusItemController: StatusItemController?

    /// Whether the process was launched by the test runner rather than by a user.
    ///
    /// The unit-test bundle uses the app as its test host, so
    /// `applicationDidFinishLaunching` runs during `xcodebuild test`. Starting
    /// the real runtime there would have genuine side effects on the machine
    /// running the tests — it would rewrite the system mouse preference,
    /// register a global hotkey, request notification permission, and add a
    /// menu-bar item (which cannot be created in a headless CI session).
    /// Tests exercise the types directly with injected dependencies, so the app
    /// stays inert under test.
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar utility: no Dock icon, no main window.
        NSApp.setActivationPolicy(.accessory)

        guard !isRunningTests else {
            Log.lifecycle.info("Launched under XCTest — skipping runtime startup")
            return
        }

        environment.start()

        statusItemController = StatusItemController(
            controller: environment.controller,
            launchAtLogin: environment.launchAtLogin,
            settings: environment.settings,
            onOpenSettings: { SettingsWindowOpener.open() },
            onOpenAbout: { AboutWindowController.shared.show() }
        )

        Log.lifecycle.info("HandSwitch launched in accessory mode")
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard !isRunningTests else { return }
        environment.stop()
    }
}
