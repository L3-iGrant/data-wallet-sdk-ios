//
//  CertificateCardCollectionViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 13/09/21.
//

import UIKit

enum ExchangeCertModel{
    case general
    case multipleInputDescriptor
    case receipt(model: ReceiptCredentialModel)
}

final class CertificateCardCollectionViewCell: UICollectionViewCell,UITableViewDelegate, UITableViewDataSource, ReceiptTableView,GenericAttributeStructureTableView {
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: ExchangeDataPreviewViewModel? {
        didSet {
            tableView.reloadInMain()
        }
    }
    var showValues = false
    var index = 0
    var mode: ExchangeCertModel = .general
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTableView()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
//        UIView.performWithoutAnimation {
//            self.superCollectionView?.layoutIfNeeded()
//            tableView.layoutIfNeeded()
//        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        debugPrint("Collection ----- cell reused")
    }
    
    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 40.0;
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 20.0;
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        switch mode {
        case .general:
            tableView.register(cellType: CovidValuesRowTableViewCell.self)
            tableView.register(cellType: ValuesRowImageTableViewCell.self)
        case .receipt:
            self.registerCellsForReceipt(tableView: tableView)
        case .multipleInputDescriptor:
            break
        }
        tableView.reloadInMain()
    }
        
    func resetTableView(){
        tableView.delegate = nil
        tableView.dataSource = nil
    }
    
    var superCollectionView: UICollectionView? {
        var view = superview
        while view != nil && !(view is UICollectionView) {
            view = view?.superview
        }
        return view as? UICollectionView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let vc = self.superCollectionView?.delegate as? ExchangeDataPreviewViewController {
            vc.updateCollectionViewHeight(cell: self)
        }
    }
//
//    override func layoutIfNeeded() {
//        super.layoutIfNeeded()
//        self.contentView.layoutIfNeeded()
//        self.contentView.updateConstraintsIfNeeded()
//    }
//
    
}

extension CertificateCardCollectionViewCell {
    func updateCellWith(viewModel: ExchangeDataPreviewViewModel,index: Int, showValues: Bool) {
        self.viewModel = viewModel
        self.index = index
        self.showValues = showValues
        if viewModel.allItemsIncludedGroups.isNotEmpty, let searchedAttr = viewModel.allItemsIncludedGroups[index].attr, let receipt = ReceiptCredentialModel.isReceiptCredentialModel(searchedAttr: searchedAttr){
            self.mode = .receipt(model: receipt)
            setupTableView()
        }
        self.tableView.reloadData()
    }
}

extension CertificateCardCollectionViewCell {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch mode {
        case .general:
            if let EBSI_model = viewModel?.EBSI_credentials {
                if EBSI_model.first?[index].value?.subType ==  EBSI_CredentialType.PDA1.rawValue {
                    return genericAttributeStructureViewNumberOfRowsInSection(section: section, model: EBSI_model.first?[index].value?.attributes, headerKey: EBSI_model.first?[index].value?.sectionStruct?[section].key ?? "")
                }
                return EBSIWallet.shared.getEBSI_V2_attributes(section: section, certModel: EBSI_model.first?[index]).count
            }  else {
                return viewModel?.allItemsIncludedGroups[index].attr?.count ?? 0
            }
        case .receipt(let model):
            return self.receiptViewNumberOfRowsInSection(section: section, model: model)
        case .multipleInputDescriptor:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch mode {
            case .general:
            if let model = viewModel?.EBSI_credentials?.first?[index].value, model.subType ==  EBSI_CredentialType.PDA1.rawValue {
                return genericAttributeStructureViewHeightForHeaderInSection(section: section)
            }
            return getHeader(section: section) != nil ? UITableView.automaticDimension : CGFloat.leastNonzeroMagnitude
            case .receipt:
                return self.receiptViewHeightForHeaderInSection(section: section)
        case .multipleInputDescriptor:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch mode {
            case .general:
            if let model = viewModel?.EBSI_credentials?.first?[index].value, model.subType ==  EBSI_CredentialType.PDA1.rawValue {
                return genericAttributeStructureViewHeightForFooterInSection(mode: .exchange, section: section)
            }
                return getHeader(section: section) != nil ? 10 : CGFloat.leastNonzeroMagnitude
            case .receipt:
                return self.receiptViewHeightForFooterInSection(mode: .exchange, section: section)
        case .multipleInputDescriptor:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch mode {
            case .general:
            if let model = viewModel?.EBSI_credentials?.first?[index].value, model.subType ==  EBSI_CredentialType.PDA1.rawValue {
                return genericAttributeStructureViewForHeaderInSection(section: section, model: model.sectionStruct?[section])
            }
                let view = GeneralTitleView.init()
                view.value = getHeader(section: section) ?? ""
                view.btnNeed = false
                return view
            case .receipt(let model):
                return self.receiptViewForHeaderInSection(section: section, model: model)
        case .multipleInputDescriptor:
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch mode {
            case .general:
            if let EBSI_model = viewModel?.EBSI_credentials {
                switch EBSI_model.first?[index].value?.subType {
                case EBSI_CredentialType.Diploma.rawValue:
                    return 3
                case EBSI_CredentialType.PDA1.rawValue:
                    return genericAttributeStructureViewNumberOfSections(mode: .exchange, headers: EBSI_model.first?[index].value?.sectionStruct ?? [])
                default:
                    return 1
                }
            } else {
                return 1
            }
            case .receipt:
            return self.receiptViewNumberOfSections(mode: .exchange)
        case .multipleInputDescriptor:
            return 0
        }
       
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch mode {
            case .general:
            if viewModel?.EBSI_credentials?.first?[index].value?.subType == EBSI_CredentialType.PDA1.rawValue {
                let cell = genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: viewModel?.EBSI_credentials?.first?[index].value?.attributes ?? [:], blurStatus: showValues, headerKey: viewModel?.EBSI_credentials?.first?[index].value?.sectionStruct?[indexPath.section].key ?? "")
                cell.layoutIfNeeded()
                return cell
            }
                let renderedAttribues = getCertData(indexPath: indexPath)
                guard let data = renderedAttribues[safe: indexPath.row] else {return UITableViewCell()}
                if data.type == .image {
                    let cell = tableView.dequeueReusableCell(with: ValuesRowImageTableViewCell.self, for: indexPath)
                    cell.setData(model: data)
                    cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
                    return cell
                }
                let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                cell.setData(model: data, blurStatus: showValues)
                cell.renderUI(index: indexPath.row, tot: renderedAttribues.count )
                cell.arrangeStackForDataAgreement()
                cell.layoutIfNeeded()
                return cell
            case .receipt(let model):
                return self.receiptTableView(tableView, cellForRowAt: indexPath, model: model, blurStatus: showValues)
        case .multipleInputDescriptor:
            return UITableViewCell()
        }
        
        
//        let cell:CertificateWithDataTableViewCell? = tableView.dequeueReusableCell(with: CertificateWithDataTableViewCell.self, for: indexPath)
//        cell?.certData = getCertData(indexPath: indexPath)
//        cell?.blurValues = showValues
//        cell?.selectionStyle = .none
//        cell?.addButton.isHidden = true
//        if let header = getHeader(indexPath: indexPath){
//            cell?.certName.text = header
//            cell?.headerStackView.isHidden = false
//        } else {
//            cell?.certName.text = ""
//            cell?.headerStackView.isHidden = true
//        }
//        return cell ?? UITableViewCell()
    }
    
    fileprivate func getHeader(section: Int) -> String? {
        if let EBSI_model = viewModel?.EBSI_credentials {
            switch EBSI_model.first?[index].value?.subType {
                case EBSI_CredentialType.Diploma.rawValue:
                    switch section {
                        case 0: return "Identifier".uppercased()
                        case 1: return "Specified by".uppercased()
                        case 2: return "was awarded by".uppercased()
                    default: return "Identifier".uppercased()
                    }
                default: return nil
            }
        }
        return nil
    }
    
    fileprivate func getCertData(indexPath: IndexPath) -> [IDCardAttributes] {
        if let EBSI_model = viewModel?.EBSI_credentials {
            return EBSIWallet.shared.getEBSI_V2_attributes(section: indexPath.section, certModel: EBSI_model.first?[index])
        } else {
            return viewModel?.allItemsIncludedGroups[index].attr?.map({ e in
                IDCardAttributes.init(type: e.value?.type ?? .string, name: trimCertNameFromSchemeID( name: e.value?.name ?? e.exchangeAttributes?.name ?? ""), value: e.value?.value)
            }) ?? []
        }
    }
    
    private func trimCertNameFromSchemeID(name: String) -> String {
        return name.stringByRemovingAll(subStrings: SupportingCertificateNameInSchema.allCases.map({ e in
            e.rawValue
        }))
    }
}

enum SupportingCertificateNameInSchema: String, CaseIterable {
    case Passport = "Passport "
    case PKPass = "PKPASS BoardingPass "
    case Aadhar = "Aadhar "
    case Covid_PH  = "Covid PH "
    case EU_Test  = "EU Test "
    case Covid_IN  = "Covid IN "
    case Covid_EU = "Covid EU "
}
