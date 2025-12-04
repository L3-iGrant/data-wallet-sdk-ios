//
//  PaymentAdditionalDetailsCVC.swift
//  dataWallet
//
//  Created by iGrant on 25/06/25.
//

import Foundation
import eudiWalletOidcIos
import UIKit

protocol PaymentAdditionalDetailsCVCDelegate: AnyObject {
    func showImageDetails(image: UIImage?)
}

final class PaymentAdditionalDetailsCVC: UICollectionViewCell {
    
    @IBOutlet weak var tableView: UITableView!
    
    var mode: ExchangeCertModel = .general
    //var record: SearchItems_CustomWalletRecordCertModel? = nil
   // var presentationDefinitionModel: PresentationDefinitionModel?
    var cellIndex: Int? = nil
    var showValues = true
    var indexPath: IndexPath?
    var currentHeight: CGFloat = 0
    var credentailModel: SearchItems_CustomWalletRecordCertModel?
    var sectionIndex: Int? = 0
    var isFromHistory: Bool? = false
    var sectionHeaderName = ""
    weak var showImageDelegate: PaymentAdditionalDetailsCVCDelegate?
    var queryItem: Any?
    
    
    weak var delegate: ExchangeDataPreviewMultipleInputDescriptorCVCDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTableView()
    }
    
    func updateBlurState(showValues: Bool) {
        self.showValues = showValues
        tableView.reloadData()
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
            tableView.register(cellType: PaymentWalletAttestationImageRowCell.self)
            tableView.register(cellType: PhotoIdWithImageCell.self)
        case .multipleInputDescriptor:
            tableView.register(cellType: CovidValuesRowTableViewCell.self)
            tableView.register(cellType: ValuesRowImageTableViewCell.self)
        case .receipt:
            break
        }
        tableView.reloadInMain()
    }
    
    func reloadAndUpdateHeight() {
        tableView.layoutIfNeeded()
        tableView.setNeedsLayout()
        let height = tableView.contentSize.height
        if currentHeight != height {
            currentHeight = height
            if let indexPath = indexPath {
                delegate?.didUpdateTableHeight(currentHeight, for: indexPath)
            }
        }
    }
    
    private func createDataAgreementButtonView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.setTitle("certificate_data_agreement_policy".localizedForSDK(), for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        //button.addTarget(self, action: #selector(tappedOnDataAgreement), for: .touchUpInside)
        button.isUserInteractionEnabled = false
        button.alpha = 0.5
        let rightArrow = UIImageView()
        rightArrow.image = UIImage(named: "ic_disabled_arrow")
        rightArrow.tintColor = .darkGray
        rightArrow.contentMode = .center
        
        containerView.addSubview(button)
        containerView.addSubview(rightArrow)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        rightArrow.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: containerView.topAnchor),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            rightArrow.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            rightArrow.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -15),
            rightArrow.widthAnchor.constraint(equalToConstant: 20),
            rightArrow.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return containerView
    }
    
    func getCertData(indexPath: IndexPath) -> [IDCardAttributes] {
        return EBSIWallet.shared.getEBSI_V2_attributes(section: indexPath.section, certModel: credentailModel)
    }
    
    func configure(with model:  SearchItems_CustomWalletRecordCertModel?, showValues: Bool) {
        self.credentailModel = model
        self.showValues = showValues
        DispatchQueue.main.async {
            self.tableView.reloadInMain()
            self.tableView.layoutIfNeeded()
        }
    }
    
    func getNameAndIDFromPresentationDefinition(index: Int) -> (String?, String?) {
        guard let data = queryItem else { return (nil, nil) }
        if let pd = data as? PresentationDefinitionModel {
            return (pd.inputDescriptors?[index].name, pd.inputDescriptors?[index].id)
        } else if let dcql = data as? DCQLQuery {
            return (nil, dcql.credentials[index].id)
        } else {
            return (nil, nil)
        }
    }
    
    func getHeaderForMultipleInputDescriptor()-> String {
        //let index = isFromHistory ?? false ? cellIndex : sectionIndex
        var headerName: String?
        if isFromHistory ?? false {
            headerName = sectionHeaderName
        } else {
            if let name = getNameAndIDFromPresentationDefinition(index: sectionIndex ?? 0).0, !name.isEmpty {
                headerName = name
            } else if let name = credentailModel?.value?.searchableText, !name.isEmpty {
                headerName = name.capitalized
            } else if let  name = getNameAndIDFromPresentationDefinition(index: sectionIndex ?? 0).1, !name.isEmpty {
                headerName = name
            } else {
                headerName =  "OpenID Credential"
            }
        }
        return headerName ?? "OpenID Credential"
    }
    
}

extension PaymentAdditionalDetailsCVC: UITableViewDataSource, UITableViewDelegate, GenericAttributeStructureTableView {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == numberOfSections(in: tableView) - 1 {
                return 1
        }
        switch mode {
        case .general:
            if credentailModel?.value?.subType ==  EBSI_CredentialType.PDA1.rawValue || credentailModel?.value?.subType ==  EBSI_CredentialType.PWA.rawValue{
                return genericAttributeStructureViewNumberOfRowsInSection(section: section, model: credentailModel?.value?.attributes, headerKey: credentailModel?.value?.sectionStruct?[section].key ?? "")
                } else if credentailModel?.value?.subType ==  EBSI_CredentialType.PhotoIDWithAge.rawValue {
                    if credentailModel?.value?.sectionStruct?[section].type == "photoIDwithImageBadge" {
                        return 1
                    } else {
                        return genericAttributeStructureViewNumberOfRowsInSection(section: section, model: credentailModel?.value?.attributes, headerKey: credentailModel?.value?.sectionStruct?[section].key ?? "")
                    }
                }
                return EBSIWallet.shared.getEBSI_V2_attributes(section: section, certModel: credentailModel).count
        case .receipt(_), .multipleInputDescriptor:
            return 0
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
    
    func calculateHeightForText(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == numberOfSections(in: tableView) - 1 {
               return nil
        }
        //FIXME: add header here, take the title from input desprictor or card title
        switch mode {
        case .general:
            if let model = credentailModel?.value, model.subType ==  EBSI_CredentialType.PDA1.rawValue || model.subType ==  EBSI_CredentialType.PWA.rawValue || model.subType ==  EBSI_CredentialType.PhotoIDWithAge.rawValue {
                //headerName = model.sectionStruct?[safe: section]?.title?.uppercased() ?? ""
                return genericAttributeStructureViewForHeaderInSection(section: section, model: model.sectionStruct?[section], textColor: credentailModel?.value?.textColor)
            }
            let view = GeneralTitleView.init()
            view.value = getHeaderForMultipleInputDescriptor()
            view.btnNeed = false
            //headerName = view.value
            return view
        case .receipt(_), .multipleInputDescriptor:
            return nil
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch mode {
            case .general:
                switch credentailModel?.value?.subType {
                case EBSI_CredentialType.Diploma.rawValue:
                    return 4
                case EBSI_CredentialType.PDA1.rawValue, EBSI_CredentialType.PWA.rawValue, EBSI_CredentialType.PhotoIDWithAge.rawValue:
                    return genericAttributeStructureViewNumberOfSections(mode: .exchange, headers: credentailModel?.value?.sectionStruct ?? []) + 1
                default:
                    return 2
                }
            case .receipt, .multipleInputDescriptor:
            return 0
        }
       
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == numberOfSections(in: tableView) - 1 {
               let cell = UITableViewCell(style: .default, reuseIdentifier: "DataAgreementCell")
               cell.backgroundColor = .clear
               
            let buttonView = createDataAgreementButtonView()
               cell.contentView.addSubview(buttonView)
               buttonView.translatesAutoresizingMaskIntoConstraints = false
               NSLayoutConstraint.activate([
                   buttonView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                   buttonView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15),
                   buttonView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15),
                   buttonView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                   buttonView.heightAnchor.constraint(equalToConstant: 45)
               ])
            cell.selectionStyle = .none
               
               return cell
           }
        switch mode {
            case .general:
            if credentailModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue || credentailModel?.value?.subType == EBSI_CredentialType.PWA.rawValue{
                let cell = genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: credentailModel?.value?.attributes ?? [:], blurStatus: showValues, headerKey: credentailModel?.value?.sectionStruct?[indexPath.section].key ?? "", textColor: credentailModel?.value?.textColor)
                cell.layoutIfNeeded()
                return cell
            } else if credentailModel?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
                if credentailModel?.value?.sectionStruct?[indexPath.section].type == "photoIDwithImageBadge" {
                    let cell = tableView.dequeueReusableCell(with: PhotoIdWithImageCell.self, for: indexPath)
                    cell.configureCell(model: credentailModel?.value?.attributes ?? [:], blureStatus: showValues)
                    cell.delegate = self
                    return cell
                } else {
                    let cell = genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: credentailModel?.value?.attributes ?? [:], blurStatus: showValues, headerKey: credentailModel?.value?.sectionStruct?[indexPath.section].key ?? "", textColor: credentailModel?.value?.textColor)
                    cell.layoutIfNeeded()
                    return cell
                }
            }
                let renderedAttribues = getCertData(indexPath: indexPath)
                guard let data = renderedAttribues[safe: indexPath.row] else {return UITableViewCell()}
                if EBSIWallet.shared.isBase64(string: data.value ?? "") {
                    let cell = tableView.dequeueReusableCell(with: ValuesRowImageTableViewCell.self, for: indexPath)
                    cell.setData(model: data)
                    cell.delegate = self
                    cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
                    return cell
                }
                let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                cell.setData(model: data, blurStatus: showValues)
                cell.renderUI(index: indexPath.row, tot: renderedAttribues.count )
                cell.arrangeStackForDataAgreement()
                cell.layoutIfNeeded()
                return cell
        case .receipt(_), .multipleInputDescriptor:
            return UITableViewCell()
        }

    }
    
}

extension PaymentAdditionalDetailsCVC: ValuesRowImageTableViewCellDelegate {
    
    func showImageDetail(image: UIImage?) {
        showImageDelegate?.showImageDetails(image: image)
    }
    
    
}
