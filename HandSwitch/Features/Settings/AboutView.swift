//
//  AboutView.swift
//  HandSwitch
//

import AppKit
import SwiftUI

/// The About view, shown as a Settings tab and in the standalone About window.
struct AboutView: View {
    private let repositoryURL = URL(string: "https://github.com/pedrobritx/handswitch")

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage ?? NSImage(size: NSSize(width: 96, height: 96)))
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            Text("HandSwitch")
                .font(.title2.weight(.semibold))

            Text("Version \(appVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Switch your mouse between right- and left-handed in a single click.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .padding(.vertical, 2)

            VStack(spacing: 8) {
                if let repositoryURL {
                    Link(destination: repositoryURL) {
                        Label("View on GitHub", systemImage: "link")
                    }
                }
                Button {
                    SystemSettingsOpener.openMouseSettings()
                } label: {
                    Label("Open System Settings › Mouse", systemImage: "gearshape")
                }
                .buttonStyle(.link)
            }

            Text("Released under the MIT License.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 360)
    }

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}
