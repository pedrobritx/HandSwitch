//
//  EventTapMechanism.swift
//  HandSwitch
//
//  The optional "instant" mechanism: swaps the primary and secondary mouse
//  buttons live with a CGEventTap while HandSwitch is running.
//

import ApplicationServices
import CoreGraphics
import Foundation
import os

/// A thread-safe flag shared between the mechanism and the C event-tap
/// callback, indicating whether the primary/secondary buttons should be swapped.
private final class SwapFlag: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: false)

    var isSwapping: Bool {
        get { state.withLock { $0 } }
        set { state.withLock { $0 = newValue } }
    }
}

/// Context passed to the C callback via its `userInfo` pointer.
///
/// It is only mutated on the main thread (where the tap's run-loop source
/// lives), so the unchecked conformance is safe in practice.
private final class EventTapContext: @unchecked Sendable {
    let swap = SwapFlag()
    var machPort: CFMachPort?
}

/// The C callback that rewrites mouse-button events when swapping is active.
private func handSwitchEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let context = Unmanaged<EventTapContext>.fromOpaque(userInfo).takeUnretainedValue()

    // The system disables a tap that is slow or after certain input; re-enable it.
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let port = context.machPort {
            CGEvent.tapEnable(tap: port, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    guard context.swap.isSwapping else { return Unmanaged.passUnretained(event) }

    let mapping: (type: CGEventType, button: CGMouseButton)?
    switch type {
    case .leftMouseDown: mapping = (.rightMouseDown, .right)
    case .leftMouseUp: mapping = (.rightMouseUp, .right)
    case .leftMouseDragged: mapping = (.rightMouseDragged, .right)
    case .rightMouseDown: mapping = (.leftMouseDown, .left)
    case .rightMouseUp: mapping = (.leftMouseUp, .left)
    case .rightMouseDragged: mapping = (.leftMouseDragged, .left)
    default: mapping = nil
    }

    guard let mapping,
          let replacement = CGEvent(
              mouseEventSource: nil,
              mouseType: mapping.type,
              mouseCursorPosition: event.location,
              mouseButton: mapping.button
          ) else {
        return Unmanaged.passUnretained(event)
    }

    // Preserve modifier flags and click count so double-clicks and drags survive.
    replacement.flags = event.flags
    replacement.setIntegerValueField(
        .mouseEventClickState,
        value: event.getIntegerValueField(.mouseEventClickState)
    )
    return Unmanaged.passRetained(replacement)
}

/// Applies handedness by intercepting and swapping mouse-button events with a
/// `CGEventTap`. Requires Accessibility permission but takes effect instantly
/// and reliably on every macOS version.
///
/// While this mechanism is active, ``HandednessController`` keeps the system
/// preference at right-handed so the two never swap the buttons twice.
@MainActor
final class EventTapMechanism: HandednessMechanism {
    private let authorization: any AccessibilityAuthorizing
    private let context = EventTapContext()
    private var runLoopSource: CFRunLoopSource?
    private var enforced: Handedness = .right

    init(authorization: any AccessibilityAuthorizing) {
        self.authorization = authorization
    }

    var capability: MechanismCapability {
        authorization.isTrusted ? .available : .needsAccessibilityPermission
    }

    func currentHandedness() -> Handedness { enforced }

    func apply(_ handedness: Handedness) throws {
        guard authorization.isTrusted else {
            throw HandednessError.accessibilityPermissionDenied
        }
        if context.machPort == nil {
            try startTap()
        }
        context.swap.isSwapping = handedness.swapsButtons
        enforced = handedness
        if let port = context.machPort {
            CGEvent.tapEnable(tap: port, enable: true)
        }
        Log.eventTap.info("Instant mode enforcing \(handedness.rawValue, privacy: .public)")
    }

    func deactivate() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let port = context.machPort {
            CGEvent.tapEnable(tap: port, enable: false)
        }
        runLoopSource = nil
        context.machPort = nil
        context.swap.isSwapping = false
        enforced = .right
        Log.eventTap.info("Instant mode deactivated")
    }

    private func startTap() throws {
        func bit(_ type: CGEventType) -> CGEventMask { CGEventMask(1) << type.rawValue }
        let mask: CGEventMask =
            bit(.leftMouseDown) | bit(.leftMouseUp) |
            bit(.rightMouseDown) | bit(.rightMouseUp) |
            bit(.leftMouseDragged) | bit(.rightMouseDragged)

        let userInfo = Unmanaged.passUnretained(context).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: handSwitchEventTapCallback,
            userInfo: userInfo
        ) else {
            Log.eventTap.error("Failed to create CGEventTap")
            throw HandednessError.eventTapCreationFailed
        }
        context.machPort = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        runLoopSource = source
        CGEvent.tapEnable(tap: tap, enable: true)
    }
}
