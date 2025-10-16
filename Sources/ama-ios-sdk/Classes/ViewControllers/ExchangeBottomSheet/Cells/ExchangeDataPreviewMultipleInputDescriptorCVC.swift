//
//  ExchangeDataPreviewMultipleInputDescriptorCVC.swift
//  dataWallet
//
//  Created by iGrant on 20/08/25.
//

import Foundation
//import OrderedDictionary
import UIKit

protocol ExchangeDataPreviewMultipleInputDescriptorCVCDelegate: AnyObject {
    func didUpdateTableHeight(_ height: CGFloat, for indexPath: IndexPath)
    func didSelectItem(id: String?)
}

class ExchangeDataPreviewMultipleInputDescriptorCVC: UICollectionViewCell {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewTrailingConstraint: NSLayoutConstraint!
    
    weak var delegate: ExchangeDataPreviewMultipleInputDescriptorCVCDelegate?
    var indexPath: IndexPath?
    var currentHeight: CGFloat = 0
    var showValues: Bool = false
    var sessionItemData: SessionItem?
    var sectionIndex: Int = 0
    var isMultipleOptions: Bool = false
    
    var credentailModel: SearchItems_CustomWalletRecordCertModel?
    weak var showImageDelegate: ExchangeBottomSheetCollectionViewCellProtocol?
    
    func reloadAndUpdateHeight() {
        tableView.layoutIfNeeded()
        //tableView.setNeedsLayout()
        let height = tableView.contentSize.height
        if currentHeight != height {
            currentHeight = height
            if let indexPath = indexPath {
                delegate?.didUpdateTableHeight(currentHeight, for: indexPath)
            }
        }
    }
    
    func updateTableViewHeight() {
        tableView.layoutIfNeeded()
        tableViewHeight.constant = tableView.contentSize.height
    }
    
    func updateBlurState(showValues: Bool) {
        self.showValues = showValues
        tableView.reloadData()
    }
    
    func genericAttributeStructureTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: OrderedDictionary<String,DWAttributesModel>,blurStatus: Bool,headerKey: String, textColor: String? = "" ) -> UITableViewCell {
        var attrArray: [IDCardAttributes] = []
        let key = headerKey
        let grouped = model.orderedValues.filter { e in
            e.parent == key
        }
        grouped.forEach { e in
            attrArray.append(IDCardAttributes(type: e.pwaType, name: e.label, value: e.value))
        }
        let sortedArry = attrArray.sorted {
            ($0.name ?? "") < ($1.name ?? "")
        }
        let renderedAttribues = sortedArry.createAndFindNumberOfLines()
        guard indexPath.row < renderedAttribues.count else { return UITableViewCell()}
        guard let data = renderedAttribues[safe: indexPath.row] else { return UITableViewCell()}
        if EBSIWallet.shared.isBase64(string: data.value ?? "") {
            let cell = tableView.dequeueReusableCell(with: ValuesRowImageTableViewCell.self, for: indexPath)
            cell.setData(model: data)
            cell.delegate = self
            cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
            return cell
        } else if data.type == .account || data.type == .card {
            let cell = tableView.dequeueReusableCell(with: PaymentWalletAttestationImageRowCell.self, for: indexPath)
            cell.selectionStyle = .none
            cell.setData(model: data, tot: renderedAttribues.count, blurStatus: blurStatus)
            cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
            if let textColor = textColor {
                cell.setCredentialBrandingColor(color:  UIColor(hex: textColor))
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
        var indexOfCheckedItem: Int?
        var checkSelected: Bool?
        if let checkedItems = sessionItemData?.checkedItem {
            checkSelected = checkedItems.contains { item in
                 item == sectionIndex
            }
        }
        if let indexOfCheckedItem = indexOfCheckedItem {
             checkSelected = sectionIndex == indexOfCheckedItem
        }
        cell.setData(model: data, blurStatus: blurStatus, isFromVerification: true)
            cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
        cell.arrangeStackForDataAgreement(isFromVerification: true)
        
        if sessionItemData != nil {
            cell.setCheckboxSelected(checkSelected ?? false, sessionItem: sessionItemData, isMultipleOptions: isMultipleOptions)
        } else {
            cell.disableCheckBox()
        }
        // Setting text color based on credential branding
        if let textColor = textColor, !textColor.isEmpty {
            cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
        }
        cell.layoutIfNeeded()
        return cell

    }
    
    var superCollectionView: UICollectionView? {
        var view = superview
        while view != nil && !(view is UICollectionView) {
            view = view?.superview
        }
        return view as? UICollectionView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 40.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.isScrollEnabled = false
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
        tableView.register(cellType: PhotoIdWithImageCell.self)
    }
    
    
    func configure(with model:  SearchItems_CustomWalletRecordCertModel?, showValues: Bool, sessionItemData: SessionItem?, sectionIndex: Int, isMultipleOptions: Bool) {
        self.credentailModel = model
        self.sessionItemData = sessionItemData
        self.showValues = showValues
        self.sectionIndex = sectionIndex
        self.isMultipleOptions = isMultipleOptions
       
        if sessionItemData != nil {
            tableView.layer.cornerRadius = 8
            tableView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            tableView.backgroundColor = .white
            tableViewLeadingConstraint.constant = 15
            tableViewTrailingConstraint.constant = 15
        } else {
            tableView.backgroundColor = .clear
            tableViewLeadingConstraint.constant = 0
            tableViewTrailingConstraint.constant = 0
        }
        DispatchQueue.main.async {
            self.tableView.reloadInMain()
            self.tableView.layoutIfNeeded()
        }
    }
    
}

extension ExchangeDataPreviewMultipleInputDescriptorCVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if credentailModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue || credentailModel?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
            return credentailModel?.value?.sectionStruct?.count ?? 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if credentailModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue {
            let key = credentailModel?.value?.sectionStruct?[section].key
            let model = credentailModel?.value?.attributes
            let numberOfCells = model?.orderedValues.filter { e in
                e.parent == key
            }
            return numberOfCells?.count ?? 0
        } else if credentailModel?.value?.subType  ==  EBSI_CredentialType.PhotoIDWithAge.rawValue {
            if credentailModel?.value?.sectionStruct?[section].type == "photoIDwithImageBadge" {
                return 1
            } else {
                let key = credentailModel?.value?.sectionStruct?[section].key
                let model = credentailModel?.value?.attributes
                let numberOfCells = model?.orderedValues.filter { e in
                    e.parent == key
                }
                return numberOfCells?.count ?? 0
            }
        } else {
            return credentailModel?.value?.EBSI_v2?.attributes?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if credentailModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue {
            let cell = genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: credentailModel?.value?.attributes ?? [:], blurStatus: showValues, headerKey: credentailModel?.value?.sectionStruct?[indexPath.section].key ?? "")
            return cell
        } else if credentailModel?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
            if credentailModel?.value?.sectionStruct?[indexPath.section].type == "photoIDwithImageBadge" {
                let cell = tableView.dequeueReusableCell(with: PhotoIdWithImageCell.self, for: indexPath)
                cell.delegate = self
                cell.configureCell(model: credentailModel?.value?.attributes ?? [:], blureStatus: showValues)
                return cell
            } else {
                let cell = genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: credentailModel?.value?.attributes ?? [:], blurStatus: showValues, headerKey: credentailModel?.value?.sectionStruct?[indexPath.section].key ?? "")
                cell.layoutIfNeeded()
                return cell
            }
        } else {
            if let att = credentailModel?.value?.EBSI_v2?.attributes {
                let sortedAttributes = att.sorted { $0.name ?? "" < $1.name ?? "" }
                if indexPath.row < sortedAttributes.count {
                    if EBSIWallet.shared.isBase64(string: sortedAttributes[indexPath.row].value ?? "") {
                        let cell = tableView.dequeueReusableCell(with: ValuesRowImageTableViewCell.self, for: indexPath)
                        cell.setData(model: sortedAttributes[indexPath.row])
                        //cell.delegate = self
                        cell.renderUI(index: indexPath.row, tot: att.count)
                        return cell
                    }
                    let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                    cell.setData(model: sortedAttributes[indexPath.row], blurStatus: showValues, isFromVerification: true)
                    cell.renderUI(index: indexPath.row, tot: att.count)
                    var indexOfCheckedItem: Int?
                    var checkSelected: Bool?
                    if let checkedItems = sessionItemData?.checkedItem {
                        checkSelected = checkedItems.contains { item in
                             item == sectionIndex
                        }
                    }
                    
                    if sessionItemData != nil {
                        cell.setCheckboxSelected(checkSelected ?? false, sessionItem: sessionItemData, isMultipleOptions: isMultipleOptions)
                    } else {
                        cell.disableCheckBox()
                    }
                    cell.arrangeStackForDataAgreement(isFromVerification: true)
                    cell.setNeedsLayout()
                    cell.layoutIfNeeded()
                    return cell
                } else {
                    return UITableViewCell()
                }
                
            } else {
                return UITableViewCell()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if credentailModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue || credentailModel?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
            guard let headerView = self.tableView(tableView, viewForHeaderInSection: section) as? GeneralTitleView else {
                return CGFloat.leastNormalMagnitude
            }
            let headerTitle = headerView.value
            if !headerTitle.isEmpty {
                let font = UIFont.systemFont(ofSize: 17)
                let width = tableView.frame.width - 40
                let height = calculateHeightForText(text: headerTitle, font: font, width: width)
                return height
            } else {
                return CGFloat.leastNormalMagnitude
            }
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func calculateHeightForText(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if credentailModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue || credentailModel?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
            guard section < credentailModel?.value?.sectionStruct?.count ?? 0 else { return nil}
            let certName = credentailModel?.value?.sectionStruct?[section].title?.uppercased() ?? ""
            if !certName.isEmpty {
                let view = GeneralTitleView.init()
                view.value = certName
                view.btnNeed = false
                view.layoutIfNeeded()
                return view
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectItem(id: credentailModel?.id)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
}

extension ExchangeDataPreviewMultipleInputDescriptorCVC: ValuesRowImageTableViewCellDelegate {
    
    func showImageDetail(image: UIImage?) {
        
        showImageDelegate?.showImageDetails(image: image)
    }
    
    
}
