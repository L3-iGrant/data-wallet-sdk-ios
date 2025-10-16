//
//  PaymentAdditionalDataRequestBottomSheetVC.swift
//  dataWallet
//
//  Created by iGrant on 07/05/25.
//

import Foundation
import eudiWalletOidcIos
import UIKit

protocol PaymentAdditionalDataRequestBottomSheetVCDelegate: AnyObject {
    func didSelectCredential(for data: String?, section: Int)
    func didScrollToCredential(at index: Int)
}

final class PaymentAdditionalDataRequestBottomSheetVC: UIViewController {
    
    @IBOutlet weak var eyeButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var dataAgreementPolicyView: UIView!
    
    @IBOutlet weak var dataAgreementPolicyButton: UIButton!
    
    @IBOutlet weak var rightArrowImageView: UIImageView!
    
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var parentViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var buttonTopeConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bgTransparentView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabelBottomConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var multipleCardsView: UIView!
    
    @IBOutlet weak var pageControll: UIPageControl!
    
    @IBOutlet weak var multipleCardsHeight: NSLayoutConstraint!
   // var presentationDefinitionModel: PresentationDefinitionModel?
    var mode: ExchangeCertModel = .general
    var record: SearchItems_CustomWalletRecordCertModel? = nil
    var headerName: String?
    var showValues = false
    var viewModel = PaymentAdditionalDataRequestBottomSheetViewModel()
    var dataAgreementView = UIView()
    var isFromHistory: Bool? = false
    var dataAgreementButton = UIButton.init(type: .custom)
    var cellIndex: Int? = nil
    var filterdRecords = [[SearchItems_CustomWalletRecordCertModel]]()
    var credentailModel: [SearchItems_CustomWalletRecordCertModel]?
    weak var delegate: PaymentAdditionalDataRequestBottomSheetVCDelegate?
    var sectionIndex: Int = 0
    var selectedCredentialIndex: Int = 0
    var sectionHeaderName = ""
    var onCredentialIndexChange: ((Int) -> Void)?
    var queryItem: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        let screenHeight = UIScreen.main.bounds.height
        let sheetHeight = screenHeight * 0.85
        parentViewHeight.constant = sheetHeight
        if isFromHistory ?? false {
            bgTransparentView.backgroundColor = .black.withAlphaComponent(0.8)
        } else {
            bgTransparentView.backgroundColor = .clear
        }
        setTitleLabel()
        
        let filteredSections = EBSIWallet.shared.exchangeDataRecordsdModel.filter { section in
            // Keep section only if ALL items have nil fundingSource
            section.allSatisfy { item in
                item.value?.fundingSource == nil
            }
        }
        filterdRecords = filteredSections
        
        pageControll.numberOfPages = credentailModel?.count ?? 0
        pageControll.hidesForSinglePage = true
        if credentailModel?.count == 1 {
            multipleCardsView.isHidden = true
            multipleCardsHeight.constant = 0
        } else {
            multipleCardsView.isHidden = false
        }
        
//        if credentailModel?.count == 1 {
//            delegate?.didSelectCredential(for: credentailModel?.first?.value?.EBSI_v2?.credentialJWT ?? "", section: cellIndex ?? 0)
//        }
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
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "PaymentAdditionalDetailsCVC", bundle: nil), forCellWithReuseIdentifier: "PaymentAdditionalDetailsCVC")
        collectionView.reloadData()
        
        
        if !(isFromHistory ?? false) &&  credentailModel?.count ?? 0 > 1 {
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let indexPath = IndexPath(item: self.selectedCredentialIndex, section: 0)
                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                self.pageControll.currentPage = self.selectedCredentialIndex
                
                let selectedData = self.credentailModel?[self.selectedCredentialIndex].value?.EBSI_v2?.credentialJWT ?? ""
                if let name = self.credentailModel?[self.selectedCredentialIndex].value?.searchableText, !name.isEmpty {
                    self.titleLabel.text = name
                }
                self.delegate?.didSelectCredential(for: selectedData, section: self.sectionIndex)
            }
        }
    }
    
    func setTitleLabel() {
        if record?.value?.subType ==  EBSI_CredentialType.PDA1.rawValue {
            titleLabel.text = getHeaderForMultipleInputDescriptor()
        } else {
            titleLabelTopConstraint.constant = 0
            titleLabelBottomConstraint.constant = 0
            titleLabel.isHidden = true
        }
    }
    
    @IBAction func eyeButtonTapped(_ sender: Any) {
        showValues = !showValues
        let config = UIImage.SymbolConfiguration(scale: .medium)
        let imageName = showValues ? "eye.slash" : "eye"
        let img = UIImage(systemName: imageName, withConfiguration: config)
        eyeButton.setImage(img, for: .normal)
        updateBlurStateForVisibleCells()
        //collectionView.reloadData()
    }
    
    private func updateBlurStateForVisibleCells() {
        let visibleCells = collectionView.visibleCells
        
        for cell in visibleCells {
            if let customCell = cell as? PaymentAdditionalDetailsCVC {
                customCell.updateBlurState(showValues: showValues)
            }
        }
    }
    
    private func createDataAgreementButtonView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.setTitle("certificate_data_agreement_policy".localized(), for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(tappedOnDataAgreement), for: .touchUpInside)
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
    
    // need to implement data agreement policy action
    @objc func tappedOnDataAgreement() {
    }
    
    func getHeaderForMultipleInputDescriptor()-> String {
        
        if let index = cellIndex {
            var title: String? = nil
            if let name = getNameAndIDFromPresentationDefinition(index: index).0, !name.isEmpty {
                title = name
            } else if let name = record?.value?.searchableText, !name.isEmpty {
                title = name.capitalized
            } else if let  name = getNameAndIDFromPresentationDefinition(index: index).1, !name.isEmpty {
                title = name
            }
            return title ?? "OpenID Credential"
        } else {
            return "OpenID Credential"
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
    
    func getCertData(indexPath: IndexPath) -> [IDCardAttributes] {
        return EBSIWallet.shared.getEBSI_V2_attributes(section: indexPath.section, certModel: record)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
}

extension PaymentAdditionalDataRequestBottomSheetVC: UITableViewDataSource, UITableViewDelegate, GenericAttributeStructureTableView {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == numberOfSections(in: tableView) - 1 {
                return 1
        }
        switch mode {
        case .general:
            if record?.value?.subType ==  EBSI_CredentialType.PDA1.rawValue || record?.value?.subType ==  EBSI_CredentialType.PWA.rawValue{
                return genericAttributeStructureViewNumberOfRowsInSection(section: section, model: record?.value?.attributes, headerKey: record?.value?.sectionStruct?[section].key ?? "")
                } else if record?.value?.subType ==  EBSI_CredentialType.PhotoIDWithAge.rawValue {
                    if record?.value?.sectionStruct?[section].type == "photoIDwithImageBadge" {
                        return 1
                    } else {
                        return genericAttributeStructureViewNumberOfRowsInSection(section: section, model: record?.value?.attributes, headerKey: record?.value?.sectionStruct?[section].key ?? "")
                    }
                }
                return EBSIWallet.shared.getEBSI_V2_attributes(section: section, certModel: record).count
        case .receipt(_), .multipleInputDescriptor:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerView = self.tableView(tableView, viewForHeaderInSection: section) as? GeneralTitleView else {
            return UITableView.automaticDimension
        }
        let headerTitle = headerView.value
        if !headerTitle.isEmpty {
            let font = UIFont.systemFont(ofSize: 17)
            let width = tableView.frame.width - 40
            let height = calculateHeightForText(text: headerTitle, font: font, width: width)
            return height
        } else {
            return UITableView.automaticDimension
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
            if let model = record?.value, model.subType ==  EBSI_CredentialType.PDA1.rawValue || model.subType ==  EBSI_CredentialType.PWA.rawValue || model.subType ==  EBSI_CredentialType.PhotoIDWithAge.rawValue {
                headerName = model.sectionStruct?[safe: section]?.title?.uppercased() ?? ""
                return genericAttributeStructureViewForHeaderInSection(section: section, model: model.sectionStruct?[section], textColor: record?.value?.textColor)
            }
            let view = GeneralTitleView.init()
            view.value = getHeaderForMultipleInputDescriptor()
            view.btnNeed = false
            headerName = view.value
            return view
        case .receipt(_), .multipleInputDescriptor:
            return nil
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch mode {
            case .general:
                switch record?.value?.subType {
                case EBSI_CredentialType.Diploma.rawValue:
                    return 4
                case EBSI_CredentialType.PDA1.rawValue, EBSI_CredentialType.PWA.rawValue, EBSI_CredentialType.PhotoIDWithAge.rawValue:
                    return genericAttributeStructureViewNumberOfSections(mode: .exchange, headers: record?.value?.sectionStruct ?? []) + 1
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
               
               return cell
           }
        switch mode {
            case .general:
            if record?.value?.subType == EBSI_CredentialType.PDA1.rawValue || record?.value?.subType == EBSI_CredentialType.PWA.rawValue{
                let cell = genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: record?.value?.attributes ?? [:], blurStatus: showValues, headerKey: record?.value?.sectionStruct?[indexPath.section].key ?? "", textColor: record?.value?.textColor)
                cell.layoutIfNeeded()
                return cell
            } else if record?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
                if record?.value?.sectionStruct?[indexPath.section].type == "photoIDwithImageBadge" {
                    let cell = tableView.dequeueReusableCell(with: PhotoIdWithImageCell.self, for: indexPath)
                    cell.configureCell(model: record?.value?.attributes ?? [:], blureStatus: showValues)
                    //cell.delegate = self
                    return cell
                } else {
                    let cell = genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: record?.value?.attributes ?? [:], blurStatus: showValues, headerKey: record?.value?.sectionStruct?[indexPath.section].key ?? "", textColor: record?.value?.textColor)
                    cell.layoutIfNeeded()
                    return cell
                }
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
        case .receipt(_), .multipleInputDescriptor:
            return UITableViewCell()
        }

    }
    
}

//extension PaymentAdditionalDataRequestBottomSheetVC: ValuesRowImageTableViewCellDelegate {
//
//    func showImageDetail(image: UIImage?) {
//        if let vc = ShowQRCodeViewController().initialize() as? ShowQRCodeViewController {
//            vc.QRCodeImage = image
//            self.present(vc: vc, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
//        }
//    }
//
//
//}

extension PaymentAdditionalDataRequestBottomSheetVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return credentailModel?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =
        collectionView.dequeueReusableCell(withReuseIdentifier:
                                            "PaymentAdditionalDetailsCVC", for: indexPath) as! PaymentAdditionalDetailsCVC
        cell.indexPath = indexPath
        cell.configure(with: (credentailModel?[safe: indexPath.item]), showValues: showValues)
        cell.layoutIfNeeded()
        cell.cellIndex = indexPath.item
        cell.sectionIndex = sectionIndex
        cell.isFromHistory = isFromHistory
        cell.sectionHeaderName = sectionHeaderName
        cell.showImageDelegate = self
        //cell.updateBlurState(showValues: showValues)
        cell.queryItem = queryItem
        DispatchQueue.main.async {
            cell.reloadAndUpdateHeight()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //sectionHeight = collectionView.frame.height
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
//        selectedCredentialIndex = page
        let selectedData = credentailModel?[page].value?.EBSI_v2?.credentialJWT ?? ""
        if let name = credentailModel?[page].value?.searchableText, !name.isEmpty {
            titleLabel.text = name
        }
        delegate?.didSelectCredential(for: selectedData, section: sectionIndex)
        delegate?.didScrollToCredential(at: page)
        onCredentialIndexChange?(page)
        pageControll.currentPage = page
        selectedCredentialIndex = page
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let customCell = cell as? PaymentAdditionalDetailsCVC {
            customCell.updateBlurState(showValues: showValues)
        }
    }
    
    
}

extension PaymentAdditionalDataRequestBottomSheetVC: ExchangeDataPreviewMultipleInputDescriptorCVCDelegate {
    
    func didSelectItem(id: String?) {
        
    }
    
    func didUpdateTableHeight(_ height: CGFloat, for indexPath: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            self?.collectionViewHeight.constant = height
//            UIView.animate(withDuration: 0.3) {
                self?.collectionView.collectionViewLayout.invalidateLayout()
//            }
        }
        
    }
    
}

extension PaymentAdditionalDataRequestBottomSheetVC: PaymentAdditionalDetailsCVCDelegate {
    
    func showImageDetails(image: UIImage?) {
        if let vc = ShowQRCodeViewController().initialize() as? ShowQRCodeViewController {
            vc.QRCodeImage = image
            self.present(vc: vc, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
        }
    }
    
}
