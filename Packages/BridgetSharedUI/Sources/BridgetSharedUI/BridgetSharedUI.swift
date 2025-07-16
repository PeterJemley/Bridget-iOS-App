// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// A reusable, HIG-compliant loading overlay for indeterminate API loading states.
public struct LoadingOverlayView: View {
    public var label: String
    public var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.7)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView(label)
                    .progressViewStyle(.circular)
                    .accessibilityLabel(Text(label))
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
    }
    public init(label: String = "Loading data…") {
        self.label = label
    }
}
