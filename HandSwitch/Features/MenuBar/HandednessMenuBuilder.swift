//
//  HandednessMenuBuilder.swift
//  HandSwitch
//
//  Builds the status-item right-click menu from the current state.
//

import AppKit

/// The actions a status-item menu can trigger. Implemented by
/// ``StatusItemController``; declared as an `@objc` protocol so the builder can
/// wire menu items to it with `#selector` without a tight type dependency.
@objc protocol MenuActionHandling: AnyObject {
    func menuToggleHandedness()
    func menuSelectRightHanded()
    func menuSelectLeftHanded()
    func menuOpenShortcutSettings()
    func menuToggleLaunchAtLogin()
    func menuOpenSettings()
    func menuOpenAbout()
    func menuQuit()
}

/// Constructs the menu shown when the user right-clicks (or control-clicks) the
/// menu-bar icon. The layout mirrors the app's documented menu structure.
@MainActor
enum HandednessMenuBuilder {
    /// The state needed to render the menu.
    struct State {
        let current: Handedness
        let launchAtLoginEnabled: Bool
        let shortcut: KeyCombo
    }

    static func build(state: State, target: NSObject & MenuActionHandling) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // Current mode (informational).
        let header = NSMenuItem(
            title: String(localized: "Current Mode: \(state.current.displayName)", comment: "Menu header showing the active mode"),
            action: nil,
            keyEquivalent: ""
        )
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        // Toggle.
        menu.addItem(item(
            title: String(localized: "Toggle Handedness", comment: "Menu item that switches the mode"),
            selector: #selector(MenuActionHandling.menuToggleHandedness),
            target: target
        ))
        menu.addItem(.separator())

        // Explicit selection with checkmarks.
        let rightItem = item(
            title: Handedness.right.displayName,
            selector: #selector(MenuActionHandling.menuSelectRightHanded),
            target: target
        )
        rightItem.state = state.current == .right ? .on : .off
        menu.addItem(rightItem)

        let leftItem = item(
            title: Handedness.left.displayName,
            selector: #selector(MenuActionHandling.menuSelectLeftHanded),
            target: target
        )
        leftItem.state = state.current == .left ? .on : .off
        menu.addItem(leftItem)
        menu.addItem(.separator())

        // Keyboard shortcut (opens Settings, shows the current combo).
        menu.addItem(item(
            title: String(localized: "Keyboard Shortcut: \(state.shortcut.displayString)", comment: "Menu item showing and editing the shortcut"),
            selector: #selector(MenuActionHandling.menuOpenShortcutSettings),
            target: target
        ))

        // Launch at login (checkmark).
        let launchItem = item(
            title: String(localized: "Launch at Login", comment: "Menu item toggling login item"),
            selector: #selector(MenuActionHandling.menuToggleLaunchAtLogin),
            target: target
        )
        launchItem.state = state.launchAtLoginEnabled ? .on : .off
        menu.addItem(launchItem)
        menu.addItem(.separator())

        // Settings, About.
        let settingsItem = item(
            title: String(localized: "Settings…", comment: "Menu item opening Settings"),
            selector: #selector(MenuActionHandling.menuOpenSettings),
            target: target
        )
        settingsItem.keyEquivalent = ","
        menu.addItem(settingsItem)

        menu.addItem(item(
            title: String(localized: "About HandSwitch", comment: "Menu item opening the About window"),
            selector: #selector(MenuActionHandling.menuOpenAbout),
            target: target
        ))
        menu.addItem(.separator())

        // Quit.
        let quitItem = item(
            title: String(localized: "Quit HandSwitch", comment: "Menu item quitting the app"),
            selector: #selector(MenuActionHandling.menuQuit),
            target: target
        )
        quitItem.keyEquivalent = "q"
        menu.addItem(quitItem)

        return menu
    }

    private static func item(title: String, selector: Selector, target: NSObject & MenuActionHandling) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        menuItem.target = target
        menuItem.isEnabled = true
        return menuItem
    }
}
