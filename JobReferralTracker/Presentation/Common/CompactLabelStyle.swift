import SwiftUI

/// Icon and title with tight spacing (List rows otherwise use a wide, fixed icon column).
struct CompactLabelStyle: LabelStyle {
    var spacing: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == CompactLabelStyle {
    static var compact: CompactLabelStyle { CompactLabelStyle() }
}

extension ReferralStatus {
    /// Title with the icon in the status color, for pickers.
    var coloredLabel: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(color)
        }
    }
}
