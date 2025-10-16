//
//  PaymentDataConfirmationBottomSheetVC.swift
//  dataWallet
//
//  Created by iGrant on 03/02/25.
//

import Foundation
import eudiWalletOidcIos
import UIKit


class PaymentDataConfirmationBottomSheetVC: UIViewController, PaymentDataConfirmationBottonSheetViewDelegate {
    func dismissVC() {
        dismiss(animated: true)
    }
    
    func presentVC(vc: UIViewController) {
        present(vc, animated: true)
    }
    
    
    func closeTapped() {
        dismiss(animated: true)
    }
    
    @IBOutlet weak var dimmedView: UIView!
    var bottomSheetView = PaymentDataConfirmationBottonSheetView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBottomSheetView()
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet && !EBSIWallet.shared.isFromPushNotification{
            dimmedView.backgroundColor = .clear
        } else {
            dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }
    
    private func setupBottomSheetView() {
        let screenHeight = UIScreen.main.bounds.height
        let sheetHeight = screenHeight * 0.85
        bottomSheetView = PaymentDataConfirmationBottonSheetView()
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomSheetView)
        NSLayoutConstraint.activate([
            bottomSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSheetView.heightAnchor.constraint(equalToConstant: sheetHeight)
        ])
        bottomSheetView.delegate = self
    }
    
}
