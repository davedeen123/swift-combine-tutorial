import Foundation
import Combine

final class LoginViewModel {

    // MARK: - Inputs (View -> ViewModel)
    let username = CurrentValueSubject<String, Never>("")
    let password = CurrentValueSubject<String, Never>("")
    let loginTapped = PassthroughSubject<Void, Never>()

    // MARK: - Outputs (ViewModel -> View)
    let isLoginEnabled: AnyPublisher<Bool, Never>
    let statusText: AnyPublisher<String, Never>
    let isLoading: AnyPublisher<Bool, Never>
    let user: AnyPublisher<User?, Never>

    // MARK: - Private Subjects (internal state)
    private let loadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let statusSubject  = CurrentValueSubject<String, Never>("Enter credentials")
    private let userSubject    = CurrentValueSubject<User?, Never>(nil)

    private let service: AuthServicing
    private var cancellables = Set<AnyCancellable>()

    init(service: AuthServicing = AuthService()) {
        self.service = service

        // Expose outputs as AnyPublisher (so View can't mutate them)
        self.isLoading  = loadingSubject.removeDuplicates().eraseToAnyPublisher()
        self.statusText = statusSubject.removeDuplicates().eraseToAnyPublisher()
        self.user       = userSubject.eraseToAnyPublisher()

        // Shared stream of latest trimmed credentials
        let credentials = Publishers.CombineLatest(username, password)
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .map { u, p in
                (u.trimmingCharacters(in: .whitespacesAndNewlines),
                 p.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .share()

        // Enable login only if validation passes and NOT loading
        let validCredentials = credentials
            .map { u, p in u.count >= 3 && p.count >= 4 }
            .removeDuplicates()

        self.isLoginEnabled = Publishers.CombineLatest(validCredentials, loadingSubject)
            .map { valid, loading in valid && !loading }
            .removeDuplicates()
            .eraseToAnyPublisher()

        // Update status text while user types (no loading here)
        credentials
            .map { u, p -> String in
                if u.isEmpty || p.isEmpty { return "Enter credentials" }
                if u.count < 3 { return "Username too short" }
                if p.count < 4 { return "Password too short" }
                return "Ready to login"
            }
            .sink { [weak self] text in
                self?.statusSubject.send(text)
            }
            .store(in: &cancellables)

        // Login request runs ONLY when button tapped
        loginTapped
            .combineLatest(credentials)     // get latest username/password at tap time
            .map { (_, pair) in pair }
            .filter { [weak self] (u, p) in
                // Optional: prevent login when already loading
                guard let self else { return false }
                return !self.loadingSubject.value && u.count >= 3 && p.count >= 4
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                // Start loading ONLY on tap
                self?.loadingSubject.send(true)
                self?.statusSubject.send("Logging in…")
                self?.userSubject.send(nil)
            })
            .flatMap { [service] (u, p) -> AnyPublisher<Result<User, AuthError>, Never> in
                service.login(username: u, password: p)
                    .map { Result.success($0) }
                    .catch { Just(Result.failure($0)) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }
                self.loadingSubject.send(false)

                switch result {
                case .success(let user):
                    self.userSubject.send(user)
                    self.statusSubject.send("Welcome, \(user.name) ✅")
                case .failure(let error):
                    self.userSubject.send(nil)
                    self.statusSubject.send(error.localizedDescription)
                }
            }
            .store(in: &cancellables)
    }
}

