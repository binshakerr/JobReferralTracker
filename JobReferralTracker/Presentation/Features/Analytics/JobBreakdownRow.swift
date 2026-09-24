import SwiftUI

/// One job's referral status breakdown.
struct JobBreakdownRow: View {
    let item: JobReferralBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.job.title)
                        .font(.headline)
                    Text(item.job.company)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(referralCountText(item.breakdown.total))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            StatusBreakdownBar(breakdown: item.breakdown)
            Text(item.breakdown.summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
