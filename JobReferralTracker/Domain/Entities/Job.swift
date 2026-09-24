import Foundation

/// A job opportunity the user is pursuing.
struct Job: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var company: String
    /// Empty when not provided.
    var location: String
    /// Empty when not provided. Not named `description` to avoid clashing with `NSObject.description` in the Data layer.
    var jobDescription: String
    let createdAt: Date
    var updatedAt: Date
}
