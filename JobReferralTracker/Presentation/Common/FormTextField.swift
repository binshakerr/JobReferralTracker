import SwiftUI

/// Text field with an inline validation message underneath.
struct FormTextField: View {
    let title: String
    @Binding var text: String
    var prompt: String?
    var error: String?
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text, prompt: prompt.map { Text($0) }, axis: axis)
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint(error ?? "")
    }
}
