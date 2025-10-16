//
//  ExchangeDataPreviewViewController+CollectionView.swift
//  dataWallet
//
//  Created by sreelekh N on 16/04/22.
//

import UIKit
//Attributes collectionView
extension ExchangeDataPreviewViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if mode == .EBSI {
            return viewModel?.EBSI_credentials?.count ?? 0
        } else {
            return viewModel?.allItemsIncludedGroups.count ?? 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =
        collectionView.dequeueReusableCell(withReuseIdentifier:
                                            "CertificateCardCollectionViewCell", for: indexPath) as! CertificateCardCollectionViewCell
        if let model = viewModel {
            cell.updateCellWith(viewModel: model, index: indexPath.row, showValues: showValues)
        }
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        viewModel?.selectedCardIndex = pageControl.currentPage
    }

}

