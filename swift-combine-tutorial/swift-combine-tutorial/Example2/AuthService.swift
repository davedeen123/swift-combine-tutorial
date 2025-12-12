import Foundation
import Combine

enum AuthError: LocalizedError {
    case invalidCredentials
    case network

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid username or password."
        case .network: return "Network error. Please try again."
        }
    }
}

protocol AuthServicing {
    func login(username: String, password: String) -> AnyPublisher<User, AuthError>
}

final class AuthService: AuthServicing {
    func login(username: String, password: String) -> AnyPublisher<User, AuthError> {
        // Simulate an API call
        Deferred {
            Future<User, AuthError> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    // Demo rule:
                    // username: "dayal", password: "1234" => success
                    if username.lowercased() == "dayal", password == "1234" {
                        let user = User(id: UUID(), name: "Dayal", token: "token_abc_123")
                        promise(.success(user))
                    } else {
                        promise(.failure(.invalidCredentials))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
