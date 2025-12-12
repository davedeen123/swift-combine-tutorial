import Foundation

struct User: Codable, Equatable {
    let id: UUID
    let name: String
    let token: String
}

