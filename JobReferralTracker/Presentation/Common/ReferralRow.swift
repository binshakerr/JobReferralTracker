import SwiftUI

/// List row for a referral: name, secondary line and status badge.
struct ReferralRow: View {
    let name: String
    let subtitle: String
    let status: ReferralStatus

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            StatusBadge(status: status)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
