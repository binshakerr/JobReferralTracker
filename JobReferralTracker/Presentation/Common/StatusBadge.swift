import SwiftUI

/// Status shown as icon + text (never color alone).
struct StatusBadge: View {
    let status: ReferralStatus

    var body: some View {
        Label(status.title, systemImage: status.systemImage)
            .labelStyle(.compact)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.15), in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Status: \(status.title)")
    }
}
