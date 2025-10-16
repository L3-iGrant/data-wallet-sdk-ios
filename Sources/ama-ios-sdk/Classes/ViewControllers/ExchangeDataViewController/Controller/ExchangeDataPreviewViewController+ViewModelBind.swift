//
//  ExchangeDataPreviewViewController+ViewModelBind.swift
//  dataWallet
//
//  Created by sreelekh N on 16/04/22.
//

import UIKit
extension ExchangeDataPreviewViewController: ExchangeDataPreviewViewModelDelegate {
    
    func goBack() {
        if let callback = completion {
            callback(true)
            return
        }
        DispatchQueue.main.async {
            UIApplicationUtils.hideLoader()
            NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
            if (self.viewModel?.isFromQR ?? false) {
                self.navigationController?.popToRootViewController(animated: true)
            } else if self.isFromSDK {
                UIApplicationUtils.showSuccessSnackbar(message: "Data has been shared successfully".localizedForSDK())
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.dismiss(animated: true)
                }
            } else {   self.navigationController?.popViewController(animated: true)
                NotificationCenter.default.post(name: Constants.didReceiveDataExchangeRequest, object: nil)
            }
        }
    }
    
    func showError(message: String) {
        
    }
    
    func refresh() {
        DispatchQueue.main.async {
            self.pageControl.numberOfPages = self.mode == .other ? self.viewModel?.allItemsIncludedGroups.count ?? 0 : self.viewModel?.EBSI_credentials?.count ?? 0
            self.collectionView.reloadData()
            self.updateDataAgreementButton()
            if (self.pageControl.numberOfPages < 2){
                self.multipleCardInfoView.isHidden = true
                self.pageControlView.isHidden = true
                self.multipleCardButton.isHidden = true
            } else {
                self.multipleCardInfoView.isHidden = false
                self.pageControlView.isHidden = false
                self.multipleCardButton.isHidden = false
            }
        }
    }
    
    func showAllViews() {
        DispatchQueue.main.async {
            self.view.subviews.forEach { view in
                view.isHidden = false
            }
        }
    }
    
    func calcualteTheMaxHeightOfColectionView(){
//        for rows in (0..<collectionView.numberOfItems(inSection: 0)){
//            if let cell =
//                collectionView.cellForItem(at: IndexPath.init(row: rows, section: 0)) as? CertificateCardCollectionViewCell{
//                var totalCollectionHeightConstraint: CGFloat = 0
//                for section in (0..<cell.tableView.numberOfSections) {
////                    totalCollectionHeightConstraint += 40
//                    for row in (0..<cell.tableView.numberOfRows(inSection: section)) {
//                        if let sub_cell = cell.tableView.cellForRow(at: IndexPath.init(row: row, section: section)) as? CovidValuesRowTableViewCell{
//                            sub_cell.arrangeStackForDataAgreement()
//                            sub_cell.layoutIfNeeded()
//                            totalCollectionHeightConstraint +=  sub_cell.frame.height + 20
//                    }
//                    }
//                }
//                if maxHeight < totalCollectionHeightConstraint {
//                    maxHeight = totalCollectionHeightConstraint
//                }
//            } else {
//                self.collectionHeightConstraint.constant =  self.collectionView.contentSize.height + 15
//            }
//        }
//        maxHeight = self.collectionView.contentSize.height
        if maxHeight > self.collectionHeightConstraint.constant {
            self.collectionHeightConstraint.constant = maxHeight
            self.collectionView.frame = CGRect.init(x: 0, y: 5, width: self.collectionView.frame.width, height: maxHeight)
            self.dynamicDataStack.frame = CGRect.init(x: 0, y: 0, width: baseTableView.frame.width, height: self.collectionHeightConstraint.constant + self.pageControlView.frame.height + 60)
            self.baseView.frame = self.dynamicDataStack.frame
            self.baseTableView.frame = self.baseView.frame
            self.collectionView.reloadInMain()
            debugPrint("baseView -- \(self.baseView.frame.height)  dynamicDataStack -- \(self.dynamicDataStack.frame.height) collection -- \(collectionHeightConstraint.constant) pageControl -- \(pageControl.frame.height)")
        }
    }
    
    func updateCollectionViewHeight(cell: CertificateCardCollectionViewCell){
        let cellHeight = cell.tableView.contentSize.height
        if maxHeight < cellHeight{
            maxHeight = cellHeight
            DispatchQueue.main.async {
                self.calcualteTheMaxHeightOfColectionView()
            }
        }
    }
}
