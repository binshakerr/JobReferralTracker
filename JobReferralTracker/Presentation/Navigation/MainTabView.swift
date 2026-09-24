import SwiftUI

/// Root tabs. Each tab has its own navigation stack and router.
struct MainTabView: View {
    let factory: ViewModelFactory

    @StateObject private var jobsRouter = Router()
    @StateObject private var analyticsRouter = Router()

    var body: some View {
        TabView {
            NavigationStack(path: $jobsRouter.path) {
                JobListView(factory: factory)
                    .navigationDestination(for: AppRoute.self) { RouteDestination(route: $0, factory: factory) }
            }
            .environmentObject(jobsRouter)
            .tabItem { Label("Jobs", systemImage: "briefcase") }

            NavigationStack(path: $analyticsRouter.path) {
                AnalyticsView(factory: factory)
                    .navigationDestination(for: AppRoute.self) { RouteDestination(route: $0, factory: factory) }
            }
            .environmentObject(analyticsRouter)
            .tabItem { Label("Analytics", systemImage: "chart.bar.xaxis") }
        }
    }
}

/// Resolves a route to its screen.
struct RouteDestination: View {
    let route: AppRoute
    let factory: ViewModelFactory

    var body: some View {
        switch route {
        case .jobDetail(let jobID):
            JobDetailView(jobID: jobID, factory: factory)
        case .referralDetail(let referralID):
            ReferralDetailView(referralID: referralID, factory: factory)
        }
    }
}
