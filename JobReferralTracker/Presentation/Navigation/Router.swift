import SwiftUI

/// Owns one tab's navigation path.
@MainActor
final class Router: ObservableObject {
    @Published var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    /// Removes `route` and everything pushed on top of it, e.g. after its content was deleted.
    func dismiss(_ route: AppRoute) {
        guard let index = path.firstIndex(of: route) else { return }
        path.removeSubrange(index...)
    }

    func contains(_ route: AppRoute) -> Bool {
        path.contains(route)
    }
}
