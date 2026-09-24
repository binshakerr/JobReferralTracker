import Foundation

/// Current time. Injected so tests control timestamps. (`Clock` is taken by the standard library.)
typealias DateProvider = @Sendable () -> Date

/// New entity identifiers. Injected so tests control IDs.
typealias IDGenerator = @Sendable () -> UUID
