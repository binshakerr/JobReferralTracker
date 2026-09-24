import SwiftUI

extension Binding where Value == Bool {
    /// `true` while `optional` holds a value; setting `false` clears it.
    init<Wrapped>(isPresent optional: Binding<Wrapped?>) {
        self.init(
            get: { optional.wrappedValue != nil },
            set: { if !$0 { optional.wrappedValue = nil } }
        )
    }
}

extension View {
    /// Shows an alert while `message` is non-nil.
    func errorAlert(_ title: String = "Something Went Wrong", message: Binding<String?>) -> some View {
        alert(title, isPresented: Binding(isPresent: message), presenting: message.wrappedValue) { _ in
            Button("OK", role: .cancel) {}
        } message: { text in
            Text(text)
        }
    }
}
