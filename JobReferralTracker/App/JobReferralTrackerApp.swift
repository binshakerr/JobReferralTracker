import SwiftUI

@main
struct JobReferralTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            // The Core Data stack and dependencies are wired in the App layer (AppBootstrapper/AppContainer).
            ContentView()
        }
    }
}
