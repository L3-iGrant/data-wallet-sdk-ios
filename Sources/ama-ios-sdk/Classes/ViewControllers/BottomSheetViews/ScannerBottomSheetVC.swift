//
//  ScannerBottomSheetVC.swift
//  ama-ios-sdk
//
//  Created by iGrant on 13/10/25.
//

import UIKit

class ScannerBottomSheetVC: UIViewController {
    
    // MARK: - UI Components
    public let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "xmark.circle.fill")
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var scannerView: UIView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
       view.backgroundColor = .black
        
        if let scannerView = scannerView {
            scannerView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(scannerView)
            
            NSLayoutConstraint.activate([
                scannerView.topAnchor.constraint(equalTo: view.topAnchor),
                scannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25)
        ])
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
}
