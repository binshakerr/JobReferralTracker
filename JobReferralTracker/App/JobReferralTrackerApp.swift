import SwiftUI

@main
struct JobReferralTrackerApp: App {
    @StateObject private var bootstrapper = AppBootstrapper()

    var body: some Scene {
        WindowGroup {
            RootView(bootstrapper: bootstrapper)
        }
    }
}
