//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 20/08/25.
//

import Foundation
import UIKit

protocol ExchangeDataPreviewMultipleInputDescriptorTVCDelegate: AnyObject {
    func refreshHeight()
    func didSelectCredential(for credential: String, forSection section: Int)
    func didScrolledSection(credentialIndex: Int, pagerIndex: Int)
    func updateHeaderTitle(_ title: String, forSection section: Int)
    func showImageDetails(image: UIImage?)
    func presentVC(vc: UIViewController)
    func didSelectItem(id: String?)
}

class ExchangeDataPreviewMultipleInputDescriptorTVC: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var pageControll: UIPageControl!
    
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var multipleCardsStackView: UIStackView!
    
    @IBOutlet weak var multipleCardsView: UIView!
    
    @IBOutlet weak var multipleCardsStackViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var issuanceTimeLabel: UILabel!
    
    
    weak var delegate: ExchangeDataPreviewMultipleInputDescriptorTVCDelegate?
    var showValues: Bool = false
    var checkBoxSelected: Bool = false
    var isMultipleOptions: Bool = false
    var sessionItemData: SessionItem?

    
    var credentailModel: [SearchItems_CustomWalletRecordCertModel]?
    var sectionIndex: Int = 0
    var selectedCredentialIndex: Int = 0
    var maxHeightsBySection: [Int: CGFloat] = [:]
    var sectionHeight: CGFloat = 0
    var sectionMaxHeights: [Int: CGFloat] = [:]
    
    override func layoutSubviews() {
           super.layoutSubviews()
           DispatchQueue.main.async { [weak self] in
               self?.collectionView.reloadData()
               //self?.collectionView.collectionViewLayout.invalidateLayout()
           }
       }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.delegate = self
        collectionView.dataSource = self
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = layout
        collectionView.isPagingEnabled = true
        collectionView.register(UINib(nibName: "ExchangeDataPreviewMultipleInputDescriptorCVC", bundle: Bundle.module), forCellWithReuseIdentifier: "ExchangeDataPreviewMultipleInputDescriptorCVC")
    }
    
    func configure(with model: [SearchItems_CustomWalletRecordCertModel], index: Int, showValues: Bool, sessionItem: SessionItem?, isMultipleOptions: Bool) {
        self.credentailModel = model
        self.showValues = showValues
        sectionIndex = index
        self.isMultipleOptions = isMultipleOptions
        sessionItemData = sessionItem
        selectedCredentialIndex = 0
        sectionMaxHeights[sectionIndex] = nil
        pageControll.numberOfPages = model.count
        if let sessionItem = sessionItem {
            pageControll.currentPage = sessionItem.selectedCredentialIndex[sectionIndex]
        }
        if let isScrollEnabled = sessionItemData?.checkedItem.contains(index) {
            collectionView.isScrollEnabled = isScrollEnabled == true
        }
        pageControll.hidesForSinglePage = true
        if model.count == 1 {
            multipleCardsView.isHidden = true
            multipleCardsStackViewHeight.constant = 0
        } else {
            multipleCardsView.isHidden = false
        }
        updateIssuedDate(date: credentailModel?[selectedCredentialIndex].value?.addedDate ?? "")
        collectionView.reloadData()
        
        if credentailModel?.count == 1 {
            delegate?.didSelectCredential(for: credentailModel?.first?.value?.EBSI_v2?.credentialJWT ?? "", forSection: sectionIndex)
        }

    }
    
    func updateIssuedDate(date: String?) {
        if let unixTimestamp = TimeInterval(date ?? "") {
            let dateFormat = DateFormatter.init()
            let date = Date(timeIntervalSince1970: unixTimestamp)
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = dateFormat.string(from: date)
            let formattedDate = dateFormat.date(from: dateString)
            issuanceTimeLabel.text = "welcome_issued_at".localizedForSDK() + (formattedDate?.timeAgoDisplay() ?? "")
        }
    }
    
    func updateBlurState(showValues: Bool) {
        self.showValues = showValues
        collectionView.reloadData()
    }
    
}

extension ExchangeDataPreviewMultipleInputDescriptorTVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return credentailModel?.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =
        collectionView.dequeueReusableCell(withReuseIdentifier:
                                            "ExchangeDataPreviewMultipleInputDescriptorCVC", for: indexPath) as! ExchangeDataPreviewMultipleInputDescriptorCVC
        cell.delegate = self
        cell.indexPath = indexPath
        guard indexPath.item < credentailModel?.count ?? 0 else { return UICollectionViewCell()}
        cell.configure(with: (credentailModel?[safe: indexPath.item]), showValues: showValues, sessionItemData: sessionItemData, sectionIndex: sectionIndex, isMultipleOptions: isMultipleOptions)
        cell.layoutIfNeeded()
        cell.showImageDelegate = self
        cell.updateBlurState(showValues: showValues)
        DispatchQueue.main.async {
            cell.reloadAndUpdateHeight()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        sectionHeight = collectionView.frame.height
        let height = sectionMaxHeights[sectionIndex] ?? collectionView.frame.height
        return CGSize(width: collectionView.frame.width, height: height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
        selectedCredentialIndex = page
        let selectedData = credentailModel?[selectedCredentialIndex].value?.EBSI_v2?.credentialJWT ?? ""
        if let name = credentailModel?[selectedCredentialIndex].value?.searchableText, !name.isEmpty {
            delegate?.updateHeaderTitle(name, forSection: sectionIndex)
        }
        delegate?.didSelectCredential(for: selectedData, forSection: sectionIndex)
        delegate?.didScrolledSection(credentialIndex: sectionIndex, pagerIndex: page)
        updateIssuedDate(date: credentailModel?[selectedCredentialIndex].value?.addedDate ?? "")
        pageControll.currentPage = page
    }
    
}

extension ExchangeDataPreviewMultipleInputDescriptorTVC: ExchangeDataPreviewMultipleInputDescriptorCVCDelegate {
    
    func didSelectItem(id: String?) {
        delegate?.didSelectItem(id: id)
    }
    
    func didUpdateTableHeight(_ height: CGFloat, for indexPath: IndexPath) {
            // Update the max height for this section if the new height is greater
            let currentMax = sectionMaxHeights[sectionIndex] ?? 0
            if height > currentMax {
                sectionMaxHeights[sectionIndex] = height
                
                // Update collection view layout
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Update height constraint
                    self.collectionViewHeightConstraint.constant = height
                    
                    // Invalidate layout to recalculate cell sizes
                    self.collectionView.collectionViewLayout.invalidateLayout()
                    
                    // Notify delegate to refresh table view
                    self.delegate?.refreshHeight()
                    
                    // Animate the changes
                    UIView.animate(withDuration: 0.3) {
                        self.layoutIfNeeded()
                    }
                }
            }
        }

    
    
}

extension ExchangeDataPreviewMultipleInputDescriptorTVC: ExchangeBottomSheetCollectionViewCellProtocol {
    func showImageDetails(image: UIImage?) {
        delegate?.showImageDetails(image: image)
    }
    
    
}
