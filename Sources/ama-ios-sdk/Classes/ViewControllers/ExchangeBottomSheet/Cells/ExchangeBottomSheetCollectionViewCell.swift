//
//  CertificateCardCollectionViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 13/09/21.
//

import UIKit
import eudiWalletOidcIos

protocol ExchangeBottomSheetCollectionViewCellProtocol: AnyObject {
    func showImageDetails(image: UIImage?)
    func didSelectItem(id: String?)
}


final class ExchangeBottomSheetCollectionViewCell: UICollectionViewCell,UITableViewDelegate, UITableViewDataSource, ReceiptTableView,GenericAttributeStructureTableView {
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: ExchangeDataPreviewViewModel? {
        didSet {
            tableView.reloadInMain()
        }
    }
    var showValues = false
    var index = 0
    var mode: ExchangeCertModel = .general
    var presentationDefinition: String? = "{}"
    var headerName: String?
    var presentationDefinitionModel: PresentationDefinitionModel?
    weak var delegate: ExchangeBottomSheetCollectionViewCellProtocol?
    
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
        tableView.rowHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        switch mode {
        case .general:
            tableView.register(cellType: CovidValuesRowTableViewCell.self)
            tableView.register(cellType: ValuesRowImageTableViewCell.self)
            tableView.register(cellType: IssuanceTimeTableViewCell.self)
        case .multipleInputDescriptor:
            tableView.register(cellType: CovidValuesRowTableViewCell.self)
            tableView.register(cellType: ValuesRowImageTableViewCell.self)
        case .receipt:
            self.registerCellsForReceipt(tableView: tableView)
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
        if let vc = self.superCollectionView?.delegate as? ExchangeDataPreviewBottomSheetVC {
            vc.updateCollectionViewHeight(cell: self)
        }
    }
    
    func getCertDetail(recordId: String,completion: @escaping(SearchItems_CustomWalletRecordCertModel?) -> Void) {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates,searchType: .searchWithId, searchValue: recordId) {[weak self] (success, searchHandler, error) in
            guard let strongSelf = self else { return}
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [weak self](fetched, response, error) in
                guard let strongSelf = self else { return}
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let certSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                if certSearchModel?.totalCount == 0 {
                    WalletRecord.shared.fetchAllCert { recordsModel in
                        let selectedCert = recordsModel?.records?.first(where: { cert in
                            cert.id == recordId
                        })
                        completion(selectedCert)
                    }
                } else {
                    completion(certSearchModel?.records?.first)
                }
            }
        }
    }
    
}

extension ExchangeBottomSheetCollectionViewCell {
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
    
    
    //set mode according to the presentation definition
    func updateCellWith(viewModel: ExchangeDataPreviewViewModel,index: Int, showValues: Bool, presentationDefinition: String?) {
        self.viewModel = viewModel
        self.index = index
        self.showValues = showValues
        if viewModel.allItemsIncludedGroups.isNotEmpty, let searchedAttr = viewModel.allItemsIncludedGroups[index].attr, let receipt = ReceiptCredentialModel.isReceiptCredentialModel(searchedAttr: searchedAttr){
            self.mode = .receipt(model: receipt)
            setupTableView()
        }
        //FIXME: add the below line if the presentation defintion contains more than 1 input descriptors
        // also to do send vp token
        
       
        let jsonData = presentationDefinition?.replacingOccurrences(of: "+", with: " ").data(using: .utf8)! ?? Data()
        presentationDefinitionModel = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: jsonData)
        
        if (presentationDefinitionModel?.inputDescriptors?.count ?? 0) > 1 {
            self.mode = .multipleInputDescriptor
        }
        self.tableView.reloadData()
            
        
        
    }
}

extension ExchangeBottomSheetCollectionViewCell {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch mode {
        case .general:
            let totalSections = tableView.numberOfSections
            let lastSectionIndex = totalSections - 1
            if section == lastSectionIndex {
                return 1
            }
            if let EBSI_model = viewModel?.EBSI_credentials {
                if EBSI_model.first?[index].value?.subType ==  EBSI_CredentialType.PDA1.rawValue {
                    return genericAttributeStructureViewNumberOfRowsInSection(section: section, model: EBSI_model.first?[index].value?.attributes, headerKey: EBSI_model.first?[index].value?.sectionStruct?[section].key ?? "")
                }
                return EBSIWallet.shared.getEBSI_V2_attributes(section: section, certModel: EBSI_model.first?[index]).count
            }  else {
                return viewModel?.allItemsIncludedGroups[index].attr?.count ?? 0
            }
        case .multipleInputDescriptor:
            if let records = viewModel?.EBSI_credentials?.first {
                var currentSection = 0
                for record in records {
                    if record.value?.subType == EBSI_CredentialType.PDA1.rawValue {
                        let pda1Sections = record.value?.sectionStruct?.count ?? 1
                        if section >= currentSection && section < currentSection + pda1Sections {
                            let pda1SectionIndex = section - currentSection
                            
                                return genericAttributeStructureViewNumberOfRowsInSection(section: currentSection, model: records[currentSection].value?.attributes, headerKey: records[currentSection].value?.sectionStruct?[pda1SectionIndex].key ?? "")
                        }
                        currentSection += pda1Sections
                    } else {
                        if section == currentSection {
                            return EBSIWallet.shared.getEBSI_V2_attributes(section: section, certModel: record).count
                        }
                        currentSection += 1
                    }
                }
            }
            return 0
        case .receipt(let model):
            return self.receiptViewNumberOfRowsInSection(section: section, model: model)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var recordID = ""
        if let id = viewModel?.EBSI_credentials?.first?[index].id, !id.isEmpty {
            recordID = id
        } else if let id = viewModel?.allItemsIncludedGroups[index].id, !id.isEmpty {
            recordID = id
        }
        delegate?.didSelectItem(id: recordID)
    }
    
    func calculateHeightForText(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        //FIXME: add header here, take the title from input desprictor or card title
        switch mode {
            case .general:
            let lastSection = tableView.numberOfSections - 1
            if section == lastSection {
                return nil
            }
            if let model = viewModel?.EBSI_credentials?.first?[index].value, model.subType ==  EBSI_CredentialType.PDA1.rawValue {
                headerName = model.sectionStruct?[safe: section]?.title?.uppercased() ?? ""
                return genericAttributeStructureViewForHeaderInSection(section: section, model: model.sectionStruct?[section])
            }
                let view = GeneralTitleView.init()
                view.value = getHeader(section: section) ?? ""
                view.btnNeed = false
                headerName = view.value
                return view
        case .multipleInputDescriptor:
            if let records = viewModel?.EBSI_credentials?.first {
                var currentSection = 0
                for (index, record) in records.enumerated() {
                    if record.value?.subType == EBSI_CredentialType.PDA1.rawValue {
                        let pda1Sections = record.value?.sectionStruct?.count ?? 1
                        
                        if section >= currentSection && section < currentSection + pda1Sections {
                            let pda1SectionIndex = section - currentSection
                            let nameValue = getHeaderForMultipleInputDescriptor(position: index).uppercased()
                            headerName = record.value?.sectionStruct?[pda1SectionIndex].title?.uppercased() ?? ""
                            return genericAttributeStructureViewForHeaderInSection(section: pda1SectionIndex, model: record.value?.sectionStruct?[pda1SectionIndex])
                        }
                        currentSection += pda1Sections
                    } else {
                        if section == currentSection {
                            let view = GeneralTitleView.init()
                            view.value = getHeaderForMultipleInputDescriptor(position: index).uppercased()
                            view.btnNeed = false
                            headerName = view.value
                            return view
                        }
                        currentSection += 1
                    }
                }
            }
            return nil
            case .receipt(let model):
            return nil
            //headerName = self.receiptViewForHeaderInSection(section: section, model: model).1
            //return self.receiptViewForHeaderInSection(section: section, model: model).0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch mode {
            case .general:
            if let EBSI_model = viewModel?.EBSI_credentials {
                switch EBSI_model.first?[index].value?.subType {
                case EBSI_CredentialType.Diploma.rawValue:
                    return 3
                case EBSI_CredentialType.PDA1.rawValue:
                    return genericAttributeStructureViewNumberOfSections(mode: .exchange, headers: EBSI_model.first?[index].value?.sectionStruct ?? []) + 1
                default:
                    return 2
                }
            } else {
                return 2
            }
        case .multipleInputDescriptor:
            if let records = viewModel?.EBSI_credentials?.first {
                var totalSections = 0
                for record in records {
                    if record.value?.subType == EBSI_CredentialType.PDA1.rawValue  {
                        totalSections += record.value?.sectionStruct?.count ?? 1
                    } else {
                        totalSections += 1
                    }
                }
                return totalSections
            } else if let allItemIncludesGroup = viewModel?.allItemsIncludedGroups, allItemIncludesGroup.isNotEmpty {
                return 1
            } else {
                return 0
            }
            case .receipt:
            return self.receiptViewNumberOfSections(mode: .exchange)
        }
       
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch mode {
            case .general:
            let totalSections = tableView.numberOfSections
            let lastSectionIndex = totalSections - 1
            if indexPath.section == lastSectionIndex {
                let cell = tableView.dequeueReusableCell(with: IssuanceTimeTableViewCell.self, for: indexPath)
                cell.selectionStyle = .none
                cell.timeLabel.font = UIFont.systemFont(ofSize: 10)
                let dateFormat = DateFormatter.init()
                if let unixTimestamp = TimeInterval(viewModel?.EBSI_credentials?.first?[index].value?.addedDate ?? "") {
                    let date = Date(timeIntervalSince1970: unixTimestamp)
                    dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let dateString = dateFormat.string(from: date)
                    let formattedDate = dateFormat.date(from: dateString)
                   
                    cell.setData(text: formattedDate?.timeAgoDisplay() ?? "", isFromExpired: false)
                } else {
                    if let id = viewModel?.allItemsIncludedGroups[index].id, !id.isEmpty {
                        self.getCertDetail(recordId: id, completion: { cert in
                            if let addedDate = cert?.value?.addedDate,   let unixTimestamp = TimeInterval(addedDate) {
                                let date = Date(timeIntervalSince1970: unixTimestamp)
                                dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                let dateString = dateFormat.string(from: date)
                                let formattedDate = dateFormat.date(from: dateString)
                               
                                cell.setData(text: formattedDate?.timeAgoDisplay() ?? "", isFromExpired: false)
                            }
                        })
                    }
                }
                return cell
            }
            if viewModel?.EBSI_credentials?.first?[index].value?.subType == EBSI_CredentialType.PDA1.rawValue {
                let cell = genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: viewModel?.EBSI_credentials?.first?[index].value?.attributes ?? [:], blurStatus: showValues, headerKey: viewModel?.EBSI_credentials?.first?[index].value?.sectionStruct?[indexPath.section].key ?? "")
                cell.layoutIfNeeded()
                return cell
            }
                let renderedAttribues = getCertData(indexPath: indexPath)
                guard let data = renderedAttribues[safe: indexPath.row] else {return UITableViewCell()}
            if EBSIWallet.shared.isBase64(string: data.value ?? "") {
                    let cell = tableView.dequeueReusableCell(with: ValuesRowImageTableViewCell.self, for: indexPath)
                    cell.setData(model: data)
                    //cell.delegate = self
                    cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
                    return cell
                }
                let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                cell.setData(model: data, blurStatus: showValues)
                cell.renderUI(index: indexPath.row, tot: renderedAttribues.count )
                cell.arrangeStackForDataAgreement()
                cell.layoutIfNeeded()
                return cell
        case .multipleInputDescriptor:
            if let records = viewModel?.EBSI_credentials?.first {
                var currentSection = 0
                for record in records {
                    if record.value?.subType == EBSI_CredentialType.PDA1.rawValue {
                        let pda1Sections = record.value?.sectionStruct?.count ?? 1
                        if indexPath.section >= currentSection && indexPath.section < currentSection + pda1Sections {
                            let pda1SectionIndex = indexPath.section - currentSection
                            
                            let cell = genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: record.value?.attributes ?? [:], blurStatus: showValues, headerKey: record.value?.sectionStruct?[pda1SectionIndex].key ?? "")
                            cell.layoutIfNeeded()
                            return cell
                        }
                        currentSection += pda1Sections
                    } else {
                        if indexPath.section == currentSection {
                            let renderedAttribues = EBSIWallet.shared.getEBSI_V2_attributes(section: currentSection, certModel: record)
                            guard let data = renderedAttribues[safe: indexPath.row] else { return UITableViewCell() }
                            if EBSIWallet.shared.isBase64( string: data.value ?? "") {
                                let cell = tableView.dequeueReusableCell(with: ValuesRowImageTableViewCell.self, for: indexPath)
                                cell.setData(model: data)
                                //cell.delegate = self
                                cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
                                return cell
                            }
                            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                            cell.setData(model: data, blurStatus: showValues)
                            cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
                            cell.arrangeStackForDataAgreement()
                            cell.layoutIfNeeded()
                            return cell
                        }
                        currentSection += 1
                    }
                }
            }
            return UITableViewCell()
            case .receipt(let model):
            return UITableViewCell()
           // return self.receiptTableView(tableView, cellForRowAt: indexPath, model: model, blurStatus: showValues, addedDate: "")
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
    
    fileprivate func getHeaderForMultipleInputDescriptor(position: Int)-> String{
        var title: String?
        if let EBSI_model = viewModel?.EBSI_credentials {
            if let name = presentationDefinitionModel?.inputDescriptors?[position].name, !name.isEmpty {
                title = name
            } else if let name = EBSI_model.first?[position].value?.searchableText , !name.isEmpty {
                title = name
            } else {
                title = presentationDefinitionModel?.inputDescriptors?[position].id
            }
            return title ?? "OpenID Credential"
        } else {
            return "OpenID Credential"
        }
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
    
    fileprivate func getCertData(indexPath: IndexPath, tableItemIndex:Int) -> [IDCardAttributes] {
        if let EBSI_model = viewModel?.EBSI_credentials {
            return EBSIWallet.shared.getEBSI_V2_attributes(section: indexPath.section, certModel: EBSI_model.first?[indexPath.section])
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

//extension ExchangeBottomSheetCollectionViewCell: ValuesRowImageTableViewCellDelegate {
//    
//    func showImageDetail(image: UIImage?) {
//        
//        delegate?.showImageDetails(image: image)
//    }
//    
//    
//}

