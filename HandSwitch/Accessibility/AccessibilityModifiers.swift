//
//  AccessibilityModifiers.swift
//  HandSwitch
//
//  Small, reusable helpers for accessibility and reduced-motion support.
//

import SwiftUI

/// Applies a subtle spring animation to changes of `value`, but honors the
/// user's "Reduce Motion" setting by disabling animation when it is on.
private struct MotionAwareAnimation<V: Equatable>: ViewModifier {
    let value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : .snappy(duration: 0.25), value: value)
    }
}

extension View {
    /// Animates changes of `value` with a calm spring, unless Reduce Motion is
    /// enabled — in which case the change is applied instantly.
    func motionAwareAnimation(_ value: some Equatable) -> some View {
        modifier(MotionAwareAnimation(value: value))
    }
}
