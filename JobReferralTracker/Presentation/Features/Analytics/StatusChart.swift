import Charts
import SwiftUI

/// Bar chart of referral counts per status.
struct StatusChart: View {
    let breakdown: StatusBreakdown

    var body: some View {
        Chart(ReferralStatus.allCases) { status in
            BarMark(
                x: .value("Status", status.title),
                y: .value("Referrals", breakdown.count(for: status))
            )
            .foregroundStyle(status.color)
            .annotation(position: .top) {
                Text("\(breakdown.count(for: status))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 180)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Referrals by status: \(breakdown.summaryText)")
    }
}
