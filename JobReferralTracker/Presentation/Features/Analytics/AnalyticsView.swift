import SwiftUI

/// Referral metrics: per-job breakdown and a unified, filterable referral list.
struct AnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel

    init(factory: ViewModelFactory) {
        _viewModel = StateObject(wrappedValue: factory.makeAnalyticsViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            controls
            Group {
                switch viewModel.segment {
                case .byJob: byJobContent
                case .allReferrals: allReferralsContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Analytics")
        .task { await viewModel.observe() }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 10) {
            Picker("View", selection: $viewModel.segment) {
                ForEach(AnalyticsViewModel.Segment.allCases) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if viewModel.segment == .allReferrals {
                filterChips
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReferralFilter.allCases, id: \.self) { filter in
                    let isSelected = viewModel.filter == filter
                    Button {
                        viewModel.filter = filter
                    } label: {
                        Text("\(filter.title) \(viewModel.filterCounts[filter, default: 0])")
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundStyle(isSelected ? Color.white : filter.color)
                            .background(isSelected ? filter.color : filter.color.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - By job

    @ViewBuilder
    private var byJobContent: some View {
        switch viewModel.analytics {
        case .loading:
            ProgressView()
        case .failed(let message):
            EmptyStateView(systemImage: "exclamationmark.triangle", title: "Couldn't Load Analytics", message: message)
        case .loaded(let analytics) where analytics.perJob.isEmpty:
            EmptyStateView(systemImage: "chart.bar", title: "Nothing to Analyze Yet",
                           message: "Add jobs and referrals to see how your referrals are progressing.")
        case .loaded(let analytics):
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(analytics.overall.total)")
                                .font(.largeTitle.bold())
                                .monospacedDigit()
                            Text(analytics.overall.total == 1 ? "referral" : "referrals")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("across \(analytics.perJob.count == 1 ? "1 job" : "\(analytics.perJob.count) jobs")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        StatusChart(breakdown: analytics.overall)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Overview")
                }

                Section("By Job") {
                    ForEach(analytics.perJob) { item in
                        NavigationLink(value: AppRoute.jobDetail(jobID: item.job.id)) {
                            JobBreakdownRow(item: item)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - All referrals

    @ViewBuilder
    private var allReferralsContent: some View {
        switch viewModel.allReferrals {
        case .loading:
            ProgressView()
        case .failed(let message):
            EmptyStateView(systemImage: "exclamationmark.triangle", title: "Couldn't Load Referrals", message: message)
        case .loaded:
            let items = viewModel.filteredReferrals
            if items.isEmpty {
                EmptyStateView(systemImage: "line.3.horizontal.decrease.circle", title: emptyTitle,
                               message: "Referrals you add to your jobs appear here.")
            } else {
                List(items) { item in
                    NavigationLink(value: AppRoute.referralDetail(referralID: item.id)) {
                        ReferralRow(name: item.referral.contactName,
                                    subtitle: "\(item.jobTitle) · \(item.company)",
                                    status: item.referral.status)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var emptyTitle: String {
        switch viewModel.filter {
        case .all: return "No Referrals Yet"
        case .status(let status): return "No \(status.title) Referrals"
        }
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AnalyticsView(factory: AppContainer.preview())
        }
        .environmentObject(Router())
    }
}
