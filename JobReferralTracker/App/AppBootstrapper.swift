import Foundation

/// Opens the local store at launch and builds the dependency container.
@MainActor
final class AppBootstrapper: ObservableObject {
    enum State {
        case loading
        case ready(AppContainer)
        case failed(message: String)
    }

    @Published private(set) var state: State = .loading

    private let makeStack: () -> CoreDataStack
    private var isBootstrapping = false

    init(makeStack: @escaping () -> CoreDataStack = { CoreDataStack() }) {
        self.makeStack = makeStack
    }

    func bootstrap() async {
        if case .ready = state { return }
        guard !isBootstrapping else { return }
        isBootstrapping = true
        defer { isBootstrapping = false }

        state = .loading
        let stack = makeStack()
        do {
            try await stack.load()
            state = .ready(AppContainer(stack: stack))
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
