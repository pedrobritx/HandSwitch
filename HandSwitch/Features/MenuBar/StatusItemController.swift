//
//  StatusItemController.swift
//  HandSwitch
//
//  Owns the menu-bar status item: a live icon, left-click to toggle, and a
//  right-click menu. Uses NSStatusItem directly for precise click routing that
//  MenuBarExtra cannot express.
//

import AppKit

/// Manages the menu-bar presence and its interactions.
@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let controller: HandednessController
    private let launchAtLogin: LaunchAtLoginService
    private let settings: SettingsStore
    private let onOpenSettings: @MainActor () -> Void
    private let onOpenAbout: @MainActor () -> Void

    init(
        controller: HandednessController,
        launchAtLogin: LaunchAtLoginService,
        settings: SettingsStore,
        onOpenSettings: @escaping @MainActor () -> Void,
        onOpenAbout: @escaping @MainActor () -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.controller = controller
        self.launchAtLogin = launchAtLogin
        self.settings = settings
        self.onOpenSettings = onOpenSettings
        self.onOpenAbout = onOpenAbout
        super.init()

        configureButton()
        updateIcon()

        // Redraw the icon whenever the mode changes (including remote changes).
        controller.onChange = { [weak self] in
            self?.updateIcon()
        }
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        button.image = MenuBarIconRenderer.image(for: controller.current)
        button.setAccessibilityLabel(String(
            localized: "HandSwitch, \(controller.current.displayName) mode. Click to switch.",
            comment: "VoiceOver label for the menu-bar item"
        ))
        button.toolTip = String(
            localized: "\(controller.current.displayName) — click to switch",
            comment: "Tooltip for the menu-bar item"
        )
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else {
            controller.toggle()
            presentErrorIfNeeded()
            return
        }

        let isSecondaryClick = event.type == .rightMouseUp
            || event.modifierFlags.contains(.control)

        if isSecondaryClick {
            showMenu()
        } else {
            controller.toggle()
            presentErrorIfNeeded()
        }
    }

    private func showMenu() {
        let state = HandednessMenuBuilder.State(
            current: controller.current,
            launchAtLoginEnabled: launchAtLogin.isEnabled,
            shortcut: settings.toggleShortcut
        )
        let menu = HandednessMenuBuilder.build(state: state, target: self)
        // Temporarily attach the menu so a click pops it, then detach so the
        // next left-click toggles again instead of opening the menu.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func presentErrorIfNeeded() {
        guard let error = controller.lastError else { return }
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = error.errorDescription
            ?? String(localized: "Couldn’t change the mouse mode", comment: "Generic error title")
        alert.informativeText = error.recoverySuggestion ?? ""

        let actionTitle = error.suggestsOpeningSystemSettings
            ? String(localized: "Open System Settings", comment: "Alert button")
            : String(localized: "Open Accessibility Settings", comment: "Alert button")
        alert.addButton(withTitle: actionTitle)
        alert.addButton(withTitle: String(localized: "Cancel", comment: "Alert button"))

        if alert.runModal() == .alertFirstButtonReturn {
            controller.openRelevantSystemSettings()
        }
        controller.clearError()
    }
}

// MARK: - MenuActionHandling

extension StatusItemController: MenuActionHandling {
    @objc func menuToggleHandedness() {
        controller.toggle()
        presentErrorIfNeeded()
    }

    @objc func menuSelectRightHanded() {
        controller.set(.right)
        presentErrorIfNeeded()
    }

    @objc func menuSelectLeftHanded() {
        controller.set(.left)
        presentErrorIfNeeded()
    }

    @objc func menuOpenShortcutSettings() {
        onOpenSettings()
    }

    @objc func menuToggleLaunchAtLogin() {
        do {
            try launchAtLogin.setEnabled(!launchAtLogin.isEnabled)
            settings.launchAtLoginEnabled = launchAtLogin.isEnabled
        } catch {
            settings.launchAtLoginEnabled = launchAtLogin.isEnabled
            Log.lifecycle.error("Launch-at-login toggle failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    @objc func menuOpenSettings() {
        onOpenSettings()
    }

    @objc func menuOpenAbout() {
        onOpenAbout()
    }

    @objc func menuQuit() {
        NSApp.terminate(nil)
    }
}
