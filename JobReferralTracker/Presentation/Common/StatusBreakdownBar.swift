import SwiftUI

/// Horizontal bar split by status proportions.
struct StatusBreakdownBar: View {
    let breakdown: StatusBreakdown
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 2) {
                if breakdown.total == 0 {
                    Capsule().fill(Color.secondary.opacity(0.2))
                } else {
                    ForEach(ReferralStatus.allCases.filter { breakdown.count(for: $0) > 0 }) { status in
                        Rectangle()
                            .fill(status.color)
                            .frame(width: segmentWidth(for: status, totalWidth: proxy.size.width))
                    }
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(breakdown.summaryText)
    }

    private func segmentWidth(for status: ReferralStatus, totalWidth: CGFloat) -> CGFloat {
        let segments = ReferralStatus.allCases.filter { breakdown.count(for: $0) > 0 }.count
        let available = max(totalWidth - CGFloat(segments - 1) * 2, 0)
        return available * CGFloat(breakdown.count(for: status)) / CGFloat(breakdown.total)
    }
}
