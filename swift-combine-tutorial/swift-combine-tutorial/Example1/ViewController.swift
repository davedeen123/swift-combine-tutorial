//
//  ViewController.swift
//  swift-combine-tutorial
//
//  Created by Dayal N D on 12/12/25.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    private let viewModel = CounterViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let incrementButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Increment", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        incrementButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(countLabel)
        view.addSubview(incrementButton)
        
        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            incrementButton.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 20),
            incrementButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        incrementButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        viewModel.$count
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.countLabel.text = "Count: \(value)"
            }
            .store(in: &cancellables)
    }
    
    @objc private func buttonTapped() {
        viewModel.increment()
    }
}

