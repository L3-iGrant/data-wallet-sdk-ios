//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 04/10/25.
//

import Foundation
import UIKit

final class WalletHomeBottomSheetViewController: UIViewController {
    private let dimmedView = UIView()
    private let containerView = UIView()
    private let contentViewController: UIViewController
    private let containerHeight: CGFloat = UIScreen.main.bounds.height * 0.85
    private let dimmedAlpha: CGFloat = 0.5
    var clearAlpha: Bool = false
    
    private var bottomConstraint: NSLayoutConstraint!
    
    init(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: Bundle.module)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDimmedView()
        setupContainerView()
        addContentViewController()
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(baseViewTapped))
            tapGesture.delegate = self
            self.view.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc func baseViewTapped() {}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showBottomSheet()
    }
    
    // MARK: - Setup
    private func setupDimmedView() {
        view.addSubview(dimmedView)
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if clearAlpha {
            dimmedView.backgroundColor = .clear
        } else {
            dimmedView.backgroundColor = UIColor.black.withAlphaComponent(dimmedAlpha)
        }
        
        dimmedView.alpha = 0
    }
    
    private func setupContainerView() {
        view.addSubview(containerView)
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 15
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        bottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: containerHeight)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: containerHeight),
            bottomConstraint
        ])
    }
    
    private func addContentViewController() {
        addChild(contentViewController)
        containerView.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
        
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func showBottomSheet() {
        UIView.animate(withDuration: 0) {
            self.dimmedView.alpha = 1.0
        }
        
        UIView.animate(withDuration: 0.35,
                       delay: 0.0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut,
                       animations: {
            self.bottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        })
    }
    
    @objc private func dismissBottomSheet() {
        UIView.animate(withDuration: 0.25, animations: {
            self.bottomConstraint.constant = self.containerHeight
            self.view.layoutIfNeeded()
        })
        
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseOut, animations: {
            self.dimmedView.alpha = 0
        }) { _ in
            self.dismiss(animated: false)
        }
    }
}

extension WalletHomeBottomSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let vc = contentViewController as? ConnectionsViewController {
            if let touchedView = touch.view, touchedView.isDescendant(of: vc.tableView) {
                return false
            }
            return true
        } else if let vc = contentViewController as? NotificationListViewController {
            if let touchedView = touch.view, touchedView.isDescendant(of: vc.tableView) {
                return false
            }
            return true
        } else if let vc = contentViewController as? DataHistoryBottomSheetVC {
            if let touchedView = touch.view, touchedView.isDescendant(of: vc.tableView) {
                return false
            }
            return true
        } else if let vc = contentViewController as? OrganizationDetailBottomSheetVC {
            if let touchedView = touch.view, touchedView.isDescendant(of: vc.tableView) {
                return false
            }
            return true
        } else if let vc = contentViewController as? ReceiptBottomSheetVC {
            if let touchedView = touch.view, touchedView.isDescendant(of: vc.tableView) {
                return false
            }
            return true
        } else if let vc = contentViewController as? BoardingPassBottomSheetVC {
            if let touchedView = touch.view, touchedView.isDescendant(of: vc.tableView) {
                return false
            }
            return true
        } else if let vc = contentViewController as? PaymentDataConfirmationMySharedDataVC {
            if let touchedView = touch.view, touchedView.isDescendant(of: vc.collectionView) {
                return false
            }
            return true
        } else if let vc = contentViewController as? PaymentDataConfirmationHeaderView {
            if let touchedView = touch.view, touchedView.isDescendant(of: vc.tableView) {
                return false
            }
            return true
        }
        return true
    }
}

