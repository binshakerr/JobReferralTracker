import SwiftUI

/// One tile per status with its count.
struct StatusCountGrid: View {
    let breakdown: StatusBreakdown

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ReferralStatus.allCases) { status in
                VStack(spacing: 4) {
                    Text("\(breakdown.count(for: status))")
                        .font(.title3.bold())
                        .monospacedDigit()
                    Label(status.title, systemImage: status.systemImage)
                        .labelStyle(.compact)
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(status.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(status.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(status.title): \(breakdown.count(for: status))")
            }
        }
    }
}
