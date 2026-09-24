import SwiftUI

/// Shows a loading or error screen until the store is open, then the main tabs.
struct RootView: View {
    @ObservedObject var bootstrapper: AppBootstrapper

    var body: some View {
        Group {
            switch bootstrapper.state {
            case .loading:
                ProgressView("Loading…")
            case .ready(let container):
                MainTabView(factory: container)
            case .failed(let message):
                EmptyStateView(
                    systemImage: "exclamationmark.triangle",
                    title: "Couldn't Open Your Data",
                    message: message,
                    actionTitle: "Try Again",
                    action: { Task { await bootstrapper.bootstrap() } }
                )
            }
        }
        .task { await bootstrapper.bootstrap() }
    }
}
