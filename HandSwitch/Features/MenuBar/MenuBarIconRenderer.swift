//
//  MenuBarIconRenderer.swift
//  HandSwitch
//
//  Renders the live menu-bar glyph: a mouse symbol with an "R"/"L" badge,
//  drawn as a template image so it tints automatically for light/dark menu bars.
//

import AppKit

/// Produces the menu-bar status image for a given handedness.
///
/// The result is a *template* image: macOS recolors it to match the menu-bar
/// appearance (light, dark, tinted, reduced-transparency), so it always looks
/// native without shipping multiple assets.
@MainActor
enum MenuBarIconRenderer {
    /// Builds the status-bar image showing the mouse glyph and the mode badge.
    static func image(for handedness: Handedness) -> NSImage {
        let badgeFont = NSFont.systemFont(ofSize: 11, weight: .bold)
        let badge = handedness.badge as NSString
        let badgeSize = badge.size(withAttributes: [.font: badgeFont])

        let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let mouse = NSImage(systemSymbolName: Handedness.symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(symbolConfiguration)
        let mouseSize = mouse?.size ?? NSSize(width: 14, height: 16)

        let spacing: CGFloat = 2
        let width = mouseSize.width + spacing + badgeSize.width
        let height = max(mouseSize.height, badgeSize.height)

        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { _ in
            mouse?.draw(in: NSRect(
                x: 0,
                y: (height - mouseSize.height) / 2,
                width: mouseSize.width,
                height: mouseSize.height
            ))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: badgeFont,
                .foregroundColor: NSColor.black
            ]
            badge.draw(
                at: NSPoint(x: mouseSize.width + spacing, y: (height - badgeSize.height) / 2),
                withAttributes: attributes
            )
            return true
        }
        image.isTemplate = true
        return image
    }
}
