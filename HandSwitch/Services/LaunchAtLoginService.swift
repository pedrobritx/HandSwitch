//
//  LaunchAtLoginService.swift
//  HandSwitch
//
//  Native launch-at-login control via ServiceManagement — no login-item hacks.
//

import Foundation
import ServiceManagement

/// Registers or unregisters HandSwitch as a login item using the modern
/// `SMAppService` API. The system, not a helper bundle, owns the login item.
@MainActor
final class LaunchAtLoginService {
    private var service: SMAppService { .mainApp }

    /// Whether HandSwitch is currently registered to launch at login.
    var isEnabled: Bool { service.status == .enabled }

    /// The raw service status, useful for surfacing "requires approval" states.
    var status: SMAppService.Status { service.status }

    /// Registers or unregisters the login item to match `enabled`.
    /// - Throws: Any error thrown by `SMAppService`.
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard service.status != .enabled else { return }
            try service.register()
            Log.lifecycle.info("Registered login item")
        } else {
            guard service.status == .enabled else { return }
            try service.unregister()
            Log.lifecycle.info("Unregistered login item")
        }
    }
}
