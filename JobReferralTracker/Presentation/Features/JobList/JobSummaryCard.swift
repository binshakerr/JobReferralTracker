import SwiftUI

/// Home-screen card: title, company, location and referral count.
struct JobSummaryCard: View {
    let summary: JobSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.job.title)
                    .font(.headline)
                Text(summary.job.company)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !summary.job.location.isEmpty {
                    Label(summary.job.location, systemImage: "mappin.and.ellipse")
                        .labelStyle(.compact)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Label(referralCountText(summary.referralCount), systemImage: "person.2.fill")
                .labelStyle(.compact)
                .font(.caption.weight(.semibold))
                .foregroundStyle(summary.referralCount > 0 ? Color.accentColor : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(summary.referralCount > 0 ? 0.12 : 0.05), in: Capsule())
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
