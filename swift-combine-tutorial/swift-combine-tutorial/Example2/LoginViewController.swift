import UIKit
import Combine

final class LoginViewController: UIViewController {

    private let viewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        bindViewModel()
        bindInputs()
    }

    private func setupUI() {
        usernameField.placeholder = "Username (try: dayal)"
        usernameField.borderStyle = .roundedRect

        passwordField.placeholder = "Password (try: 1234)"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true

        loginButton.setTitle("Login", for: .normal)
        loginButton.isEnabled = false

        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [usernameField, passwordField, loginButton, spinner, statusLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        loginButton.addTarget(self, action: #selector(loginPressed), for: .touchUpInside)
    }

    private func bindInputs() {
        // UITextField -> ViewModel input subjects
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: usernameField)
            .compactMap { ($0.object as? UITextField)?.text }
            .sink { [weak self] text in self?.viewModel.username.send(text) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: passwordField)
            .compactMap { ($0.object as? UITextField)?.text }
            .sink { [weak self] text in self?.viewModel.password.send(text) }
            .store(in: &cancellables)
    }

    private func bindViewModel() {
        // Output -> UI (assign / sink)

        viewModel.isLoginEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: loginButton)   // assign subscriber
            .store(in: &cancellables)

        viewModel.statusText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.statusLabel.text = text
            }
            .store(in: &cancellables)

        viewModel.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                loading ? self.spinner.startAnimating() : self.spinner.stopAnimating()
                self.view.isUserInteractionEnabled = !loading
            }
            .store(in: &cancellables)

        viewModel.user
            .compactMap { $0 } // only on success
            .receive(on: DispatchQueue.main)
            .sink { user in
                print("Logged in user:", user)
            }
            .store(in: &cancellables)
    }

    @objc private func loginPressed() {
        viewModel.loginTapped.send(())
    }
}
