//
//  PaymentDataConfirmationMySharedDataVC.swift
//  dataWallet
//
//  Created by iGrant on 11/12/24.
//

import Foundation
import UIKit

class PaymentDataConfirmationMySharedDataVC: UIViewController, CustomNavigationBarIconViewDelegate, OrganizationHeaderDelegate {
    func updateHeaderHeight(height: CGFloat) {
        
    }
    
    
    func getHeaderFetchedImage(image: UIImage) {
        let dominantClr = image.getDominantColor()
        let isLight = dominantClr.isLight()
        let color = isLight ?? false ? UIColor.black : UIColor.white
        //headerView.addGradient(color: color)
        imageLightValue = isLight
    }
    
    func updatePageTitle(title: String) {
        
    }
    
    
    let headerView = OrganizationHeaderView()
    let bottomSheetHeaderView = BottomSheetHeaderView()
    let paymentDataView = PaymentDataConfirmationHeaderView()
    let pwaView = PWAHistoryView()
    var viewModel: PaymentDataConfirmationMySharedDataViewModel?
    let headerHeight: CGFloat = 150
    let collectionView = UICollectionView.getCV()
    var showValues = false
    let backNavIcon = CustomNavigationBarIconView()
    let eyeNavIcon = CustomNavigationBarIconView()
    var isIncludeFunding: Bool = false
    var viewMode: ViewMode = .FullScreen
    var heightConstant: CGFloat = 230
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if isDark ?? false {
            return .lightContent
        } else {
            return .darkContent
        }
    }
    
    var isDark: Bool? {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    var imageLightValue: Bool? {
        didSet {
            isDark = imageLightValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = #colorLiteral(red: 0.9490196078, green: 0.9490196078, blue: 0.9647058824, alpha: 1)
        if viewMode == .BottomSheet {
            heightConstant = 150
//            bottomSheetHeaderView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: heightConstant)
//            view.addSubview(bottomSheetHeaderView)
            bottomSheetHeaderView.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(bottomSheetHeaderView)
                
                NSLayoutConstraint.activate([
                    bottomSheetHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
                    bottomSheetHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    bottomSheetHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    bottomSheetHeaderView.heightAnchor.constraint(equalToConstant: heightConstant)
                ])
            setBottomSheetHeaderContent()
        } else {
            heightConstant = 230
            headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: heightConstant)
            view.addSubview(headerView)
            //headerView.setCoverImageHeight()
            setHeaderContent()
        }
        if isIncludeFunding && viewModel?.history?.type != HistoryType.exchange.rawValue {
            pwaView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pwaView)
            NSLayoutConstraint.activate([
                pwaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pwaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                pwaView.topAnchor.constraint(equalTo: view.topAnchor, constant: heightConstant),
                pwaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
            setDetailsData2()
        } else {
            let screenHeight = UIScreen.main.bounds.height
            paymentDataView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(paymentDataView)
            NSLayoutConstraint.activate([
                paymentDataView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                paymentDataView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                paymentDataView.topAnchor.constraint(equalTo: view.topAnchor, constant: heightConstant),
                paymentDataView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            setDetailsData()
        }
        addCustomBackTabIcon()
        addCustomEyeTabIcon()
        updateNavigationContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func addCustomBackTabIcon() {
        backNavIcon.tag = 0
        backNavIcon.frame = CGRect(x: 0, y: 0, width: self.topAreaHeight, height: self.topAreaHeight)
        let barbtnItem = UIBarButtonItem(customView: backNavIcon)
        backNavIcon.delegate = self
        self.navigationItem.leftBarButtonItem = barbtnItem
    }
    
    private func addCustomEyeTabIcon() {
        eyeNavIcon.tag = 1
        eyeNavIcon.frame = CGRect(x: 0, y: 0, width: self.topAreaHeight, height: self.topAreaHeight)
        let barbtnItem = UIBarButtonItem(customView: eyeNavIcon)
        eyeNavIcon.delegate = self
        eyeNavIcon.updateImageHeight(update: 5)
        eyeNavIcon.setRight()
        self.navigationItem.rightBarButtonItem = barbtnItem
    }
    
    private func setHeaderContent() {
        if let model = viewModel {
            headerView.delegate = self
            headerView.setData(model: model)
        }
    }
    
    private func setBottomSheetHeaderContent() {
        if let model = viewModel {
            bottomSheetHeaderView.bottomSheetDelegate = self
            bottomSheetHeaderView.setData(model: model)
        }
    }
    
    
    func setDetailsData() {
        if let model = viewModel {
            paymentDataView.setData(model: model, blurStatus: showValues)
            paymentDataView.delegate = self
        }
    }
    
    func setDetailsData2() {
        if let model = viewModel {
            pwaView.setData(model: model, blurStatus: showValues)
        }
    }
    
    func cusNavtappedAction(tag: Int) {
        switch tag {
        case 1:
            self.showValues.toggle()
            self.updateNavigationContent()
        default:
            self.returnBack()
        }
    }
    
    private func updateNavigationContent() {
        if !self.showValues {
            eyeNavIcon.iconImg.image = "eye".getImage()
        } else {
            eyeNavIcon.iconImg.image = "eye.slash".getImage()
        }
        setDetailsData()
        setDetailsData2()
    }
    
}

extension PaymentDataConfirmationMySharedDataVC: PaymentDataConfirmationHeaderViewDelegate {
    
    func present(vc: UIViewController) {
        present(vc, animated: true)
    }
    
}

extension PaymentDataConfirmationMySharedDataVC: BottomSheetHeaderViewDelegate {
    
    func eyeButtonAction(showValue: Bool) {
        self.showValues = showValue
        setDetailsData()
        setDetailsData2()
    }
    
    
    func closeAction() {
        self.dismiss(animated: true)
        //self.navigationController?.popViewController(animated: true)
    }
    
    
}
