//
//  OrganizationDetailViewController+TableView.swift
//  dataWallet
//
//  Created by sreelekh N on 14/12/21.
//

import UIKit
extension OrganizationDetailViewController: UITableViewDelegate, UITableViewDataSource, ReceiptTableView, GenericAttributeStructureTableView {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch viewModel?.loadUIFor {
        case .history:
            if viewModel?.isEBSI_Diploma() ?? false{
                return 5
            }else if viewModel?.history?.value?.history?.certSubType == EBSI_CredentialType.PDA1.rawValue  {
                var requiredData: SearchItems_CustomWalletRecordCertModel?
                if viewModel?.homeData == nil {
                    requiredData = viewModel?.homeDataList?.records?.first
                } else {
                    requiredData = viewModel?.homeData
                }
                return genericAttributeStructureViewNumberOfSections(mode: .view, headers: requiredData?.value?.sectionStruct ?? []) + 3
            } else if viewModel?.history?.value?.history?.pullDataNotification != nil {
                return 4
            } else if viewModel?.isMultipleInputDescriptors() ?? false {
                if let records = viewModel?.homeDataList?.records {
                    var totalSections = 0
                    for record in records {
                        if record.value?.subType == EBSI_CredentialType.PDA1.rawValue {
                            totalSections += record.value?.sectionStruct?.count ?? 1
                        } else {
                            totalSections += 1
                        }
                    }
                    return totalSections + 3
                }
            } else if viewModel?.homeDataList?.records != nil {
                return (viewModel?.homeDataList?.records?.count ?? 0) + 3
            }
            return 4
        case .receiptHistory:
            if viewModel?.history?.value?.history?.pullDataNotification != nil {
                return 0
                //return receiptViewNumberOfSections(mode: .issue, isFromSharedData: true) + 3
            }
            return 0
            //return receiptViewNumberOfSections(mode: .issue, isFromSharedData: true) + 2
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch viewModel?.loadUIFor {
        case .history:
            switch section {
            case 0: return 5
            case tableView.numberOfSections - 2:
                var height: CGFloat = 0
                if viewModel?.history?.value?.history?.pullDataNotification != nil {
                    let name = "welcome_data_using_service".localize
                    let font = UIFont.systemFont(ofSize: 17)
                    let width = tableView.frame.width - 40
                    height = calculateHeightForText(text: name , font: font, width: width)
                } else {
                    height = 0
                }
                return height
            case tableView.numberOfSections - 1: return 5
            default:
                guard let headerView = self.tableView(tableView, viewForHeaderInSection: section) as? GeneralTitleView else {
                    return CGFloat.leastNormalMagnitude
                }
                let headerTitle = headerView.value
                if !headerTitle.isEmpty {
                    let font = UIFont.systemFont(ofSize: 17)
                    let width = tableView.frame.width - 40
                    let height = calculateHeightForText(text: headerTitle, font: font, width: width)
                    return height + 10
                } else {
                    return CGFloat.leastNormalMagnitude
                }
            }
        case .receiptHistory:
            switch section {
            case 0: return 5
            case tableView.numberOfSections - 1: return 5
            default:
                let font = UIFont.systemFont(ofSize: 17)
                let width = tableView.frame.width - 40
                return 0
//                let height = calculateHeightForText(text: headerName ?? "", font: font, width: width)
//                if headerName == "" || headerName == nil {
//                    return UITableView.automaticDimension
//                } else {
//                    return height
//                }
            }
        default:
            return 5
        }
    }
    
    func calculateHeightForText(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = GeneralTitleView()
        view.btnNeed = false
        var name =  viewModel?.history?.value?.history?.name ?? viewModel?.history?.value?.history?.certSubType
        switch viewModel?.loadUIFor {
        case .history:
            switch section {
            case 0: return nil
            case tableView.numberOfSections - 2:
                if viewModel?.history?.value?.history?.pullDataNotification != nil && tableView.numberOfSections - 2 == section{
                    name = "welcome_data_using_service".localizedForSDK()
                } else {
                    return nil
                }
                view.setLeftPadding(padding: 20)
                view.value = name?.localizedForSDK().localizedUppercase ?? ""
                return view
            case tableView.numberOfSections - 1: return nil
            default:
                if viewModel?.isEBSI_Diploma() ?? false {
                        switch section - 1 {
                        case 0: name = "Identifier".uppercased()
                        case 1: name = "Specified by".uppercased()
                        case 2: name = "was awarded by".uppercased()
                        default: name = "Identifier".uppercased()
                    }
                } else if viewModel?.history?.value?.history?.certSubType == EBSI_CredentialType.PDA1.rawValue {
                    var requiredData: SearchItems_CustomWalletRecordCertModel?
                    if viewModel?.homeData == nil {
                        requiredData = viewModel?.homeDataList?.records?.first
                    } else {
                        requiredData = viewModel?.homeData
                    }
                    return genericAttributeStructureViewForHeaderInSection(section: section, model: requiredData?.value?.sectionStruct?[section - 1])
                } else if viewModel?.history?.value?.history?.pullDataNotification != nil && tableView.numberOfSections - 2 == section {
                    name = "Data Using Service".localize
                } else if viewModel?.isMultipleInputDescriptors() ?? false  {
                    if let records = viewModel?.homeDataList?.records {
                                var currentSection = 1
                        for (index, record) in records.enumerated() {
                                    if record.value?.subType == EBSI_CredentialType.PDA1.rawValue {
                                        

                                        let pda1Sections = record.value?.sectionStruct?.count ?? 1
                                        if section >= currentSection && section < currentSection + pda1Sections {
                                            let pda1SectionIndex = section - currentSection
                                            var name: String = ""
                                            if let text = viewModel?.getNameAndIdFromInputDescriptor(index: index).0, !text.isEmpty {
                                                name = text.uppercased()
                                            } else if let text = viewModel?.history?.value?.history?.credentials?.records?[index].value?.searchableText, !text.isEmpty {
                                                name = text
                                            } else if let text = viewModel?.getNameAndIdFromInputDescriptor(index: index).1, !text.isEmpty {
                                                name = text
                                            }
                                            headerName = record.value?.sectionStruct?[pda1SectionIndex].title?.uppercased() ?? ""
                                            return genericAttributeStructureViewForHeaderInSection(section: pda1SectionIndex, model: record.value?.sectionStruct?[pda1SectionIndex])
                                        }
                                        currentSection += pda1Sections
                                    } else {
                                        if section == currentSection {
                                            let view = GeneralTitleView.init()
                                            view.btnNeed = false
                                            view.setLeftPadding(padding: 20)
                                            var name: String = ""
                                            if let text = viewModel?.getNameAndIdFromInputDescriptor(index: index).0, !text.isEmpty {
                                                name = text.uppercased()
                                            } else if let text = viewModel?.history?.value?.history?.credentials?.records?[index].value?.searchableText, !text.isEmpty {
                                                name = text
                                            }
                                            view.value = name
                                            view.btnNeed = false
                                            headerName = view.value
                                            return view
                                        }
                                        currentSection += 1
                                    }
                                }
                            }
                } else if viewModel?.homeDataList?.records != nil {
                    let view = GeneralTitleView.init()
                    view.btnNeed = false
                    view.setLeftPadding(padding: 20)
                    if viewModel?.history?.value?.history?.type == HistoryType.exchange.rawValue {
                        var name: String = ""
                        if let text = viewModel?.getNameFromPresentationDefinition(), !text.isEmpty {
                            name = text.uppercased()
                        } else if let text = viewModel?.getNameAndIdFromInputDescriptor(index: 0).0,  !text.isEmpty {
                            name = text.uppercased()
                        } else if let text = viewModel?.history?.value?.history?.credentials?.records?[section - 1].value?.searchableText, !text.isEmpty {
                            name = text
                        } else if let text = viewModel?.history?.value?.history?.certSubType, !text.isEmpty {
                            name = text
                        }
                        view.value = name
                    } else {
                        view.value = viewModel?.getHeaderForMultipleInputDescriptor(position: section - 1) ?? ""
                    }
                    return view
                }
                view.setLeftPadding(padding: 20)
                view.value = name?.localizedForSDK().localizedUppercase ?? ""
                // Setting text color based on credential branding
                if let textColor = viewModel?.history?.value?.history?.display?.textColor {
                    view.lbl.textColor = UIColor(hex: textColor)
                }
                return view
            }
        case .receiptHistory(model: let model):
            switch section {
                case 0: return nil
                case tableView.numberOfSections - 1: return nil
                default:
                return nil
//                headerName = receiptViewForHeaderInSection(section: section - 1, model: model).1
//                return receiptViewForHeaderInSection(section: section - 1, model: model).0
            }
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel?.loadUIFor {
        case .history:
            switch section {
            case 0: return 1
            case tableView.numberOfSections - 2: return 1
            case tableView.numberOfSections - 1: return 1
            default:
                // pull data notification - show data using org
                if viewModel?.history?.value?.history?.pullDataNotification != nil && tableView.numberOfSections - 2 == section {
                    return 1
                }
                if viewModel?.history?.value?.history?.certSubType == EBSI_CredentialType.PDA1.rawValue {
                    var requiredData: SearchItems_CustomWalletRecordCertModel?
                    if viewModel?.homeData == nil {
                        requiredData = viewModel?.homeDataList?.records?.first
                    } else {
                        requiredData = viewModel?.homeData
                    }
                    return genericAttributeStructureViewNumberOfRowsInSection(section: section, model: requiredData?.value?.attributes ?? [:], headerKey: requiredData?.value?.sectionStruct?[section - 1].key ?? "")
                }
                else if viewModel?.isMultipleInputDescriptors() ?? false {
                    if let records = viewModel?.homeDataList?.records {
                        var currentSection = 1
                        for record in records {
                            if record.value?.subType == EBSI_CredentialType.PDA1.rawValue {
                                let pda1Sections = record.value?.sectionStruct?.count ?? 1
                                if section >= currentSection && section < currentSection + pda1Sections {
                                    let pda1SectionIndex = section - currentSection

                                        return genericAttributeStructureViewNumberOfRowsInSection(section: currentSection, model: record.value?.attributes, headerKey: record.value?.sectionStruct?[pda1SectionIndex].key ?? "")
                                }
                                currentSection += pda1Sections
                            } else {
                                if section == currentSection {
                                    return record.value?.EBSI_v2?.attributes?.count ?? 0
                                }
                                currentSection += 1
                            }
                        }
                    }
                    return 0
                } else if viewModel?.homeDataList?.records != nil {
                    let record = viewModel?.homeDataList?.records?[safe: section - 1]
                    return record?.value?.EBSI_v2?.attributes?.count ?? 0
                }
                return EBSIWallet.shared.getEBSI_V2_attributes(section: section, history: viewModel?.history?.value?.history).count
            }
        case .receiptHistory(model: let model):
            switch section {
            case 0: return 1
            case tableView.numberOfSections - 1: return 1
            default:
                // pull data notification - show data using org
                if viewModel?.history?.value?.history?.pullDataNotification != nil && tableView.numberOfSections - 2 == section {
                    return 1
                }
                return receiptViewNumberOfRowsInSection(section: section - 1, model: model)
            }
        case .genericCard:
            return self.viewModel?.homeData == nil ? 3 : 4
        case .EBSI:
            return 4
        case .orgDetail:
            return 4
        default:
            return 4
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch viewModel?.loadUIFor {
        case .history,.receiptHistory:
            let desc = self.viewModel?.orgInfo?.organisationInfoModelDescription ?? self.viewModel?.history?.value?.history?.connectionModel?.value?.orgDetails?.organisationInfoModelDescription
            switch indexPath.section {
            case 0:
                if desc?.isEmpty ?? true {
                    return 0
                } else {
                    return UITableView.automaticDimension
                }
            case tableView.numberOfSections - 1:
                return 55
            default:
                return UITableView.automaticDimension
            }
        case .genericCard:
            return (indexPath.row == 3) ? 65 : UITableView.automaticDimension
        case .EBSI:
            let desc = self.viewModel?.orgInfo?.organisationInfoModelDescription ?? self.viewModel?.connectionModel?.value?.orgDetails?.organisationInfoModelDescription
            switch indexPath.row {
            case 0:
                if desc?.isEmpty ?? true {
                    return 0
                } else {
                    return UITableView.automaticDimension
                }
            case 3:
                return 65
                //return UITableView.automaticDimension
            default:
                return 65
            }
        case .orgDetail:
            switch indexPath.row {
            case 0:
                return UITableView.automaticDimension
            case 3:
               // return 120
                return 65
            default:
                return 65
            }
        default:
            switch indexPath.row {
            case 0:
                return UITableView.automaticDimension
            default:
                return 65
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel?.loadUIFor {
        case .history:
            switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCell(with: OverViewTableViewCell.self, for: indexPath)
                let desc = self.viewModel?.orgInfo?.organisationInfoModelDescription ?? self.viewModel?.history?.value?.history?.connectionModel?.value?.orgDetails?.organisationInfoModelDescription
                if desc?.isEmpty ?? true {
                    let cell = UITableViewCell()
                    cell.backgroundColor = .clear
                    return cell
                }
                cell.desLbl.text = desc
                cell.titleLbl.text = "Overview".localizedForSDK()
                // Setting text color based on credential branding
                if let textColor = self.viewModel?.history?.value?.history?.display?.textColor {
                    cell.setTitleColor(color: UIColor(hex: textColor))
                }
                return cell
            case tableView.numberOfSections - 2:
                if viewModel?.history?.value?.history?.pullDataNotification == nil {
                    let cell = tableView.dequeueReusableCell(with: IssuanceTimeTableViewCell.self, for: indexPath)
                    let dateFormats = ["yyyy-MM-dd hh:mm:ss.SSSSSS a'Z'", "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"]
                    let historyDate = DateUtils.shared.parseDate(from: viewModel?.history?.value?.history?.date ?? "", formats: dateFormats)
                    if let notifDate = historyDate {
                        // Setting text color based on credential branding
                        if self.viewModel?.history?.value?.history?.display?.textColor != nil {
                            cell.setTextColor(colour: UIColor(hex: self.viewModel?.history?.value?.history?.display?.textColor ?? ""))
                        }
                        cell.setData(text: notifDate.timeAgoDisplay(), isFromExchange: viewModel?.history?.value?.history?.type == HistoryType.exchange.rawValue)
                    }
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier:"NotificationTableViewCell",for: indexPath) as! NotificationTableViewCell
                    let controllerDetails = viewModel?.history?.value?.history?.pullDataNotification?.controllerDetails
                    cell.certName.text =  controllerDetails?.organisationName ?? ""
                    cell.notificationType.text = controllerDetails?.location
                    let dateFormat = DateFormatter.init()
                    dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
                    dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
                    if let notifDate = dateFormat.date(from: viewModel?.history?.value?.history?.date ?? "") {
                        cell.time.text = notifDate.timeAgoDisplay()
                    }
                    UIApplicationUtils.shared.setRemoteImageOn(cell.orgImage, url: controllerDetails?.logoImageURL ?? "")
                    cell.configForPullDataNotification()
                    cell.selectionStyle = .none
                    return cell
                }
                
            case tableView.numberOfSections - 1:
                    let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                    cell.title = "Data Agreement Policy".localizedForSDK()
                    cell.renderFor = .forwardPolicy
                    if viewModel?.history?.value?.history?.dataAgreementModel == nil {
                        if let textColor = self.viewModel?.history?.value?.history?.display?.textColor {
                            cell.backView.backgroundColor = UIColor(hex: textColor).withAlphaComponent(0.1)
                            cell.lbl.textColor = UIColor(hex: textColor).withAlphaComponent(0.5)
                        } else {
                            cell.renderFor = .inActive
                        }
                    } else if let textColor = self.viewModel?.history?.value?.history?.display?.textColor {
                        cell.setCredentialColor(textColor: UIColor(hex: textColor))
                    }
                    return cell
                
            default:
                // if it is a pullDataNotification
                if viewModel?.history?.value?.history?.pullDataNotification != nil && tableView.numberOfSections - 2 == indexPath.section {
                    let cell = tableView.dequeueReusableCell(withIdentifier:"NotificationTableViewCell",for: indexPath) as! NotificationTableViewCell
                    let controllerDetails = viewModel?.history?.value?.history?.pullDataNotification?.controllerDetails
                    cell.certName.text =  controllerDetails?.organisationName ?? ""
                    cell.notificationType.text = controllerDetails?.location
                    let dateFormat = DateFormatter.init()
                    dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
                    if let notifDate = dateFormat.date(from: viewModel?.history?.value?.history?.date ?? "") {
                        cell.time.text = notifDate.timeAgoDisplay()
                    }
                    UIApplicationUtils.shared.setRemoteImageOn(cell.orgImage, url: controllerDetails?.logoImageURL ?? "")
                    cell.configForPullDataNotification()
                    cell.selectionStyle = .none
                    return cell
                }
                var history = [IDCardAttributes]()
                history = self.viewModel?.history?.value?.history?.attributes ?? []
                if viewModel?.isEBSI() ?? false {
                    if viewModel?.history?.value?.history?.certSubType == EBSI_CredentialType.PDA1.rawValue {
                        var requiredData: SearchItems_CustomWalletRecordCertModel?
                        if viewModel?.homeData == nil {
                            requiredData = viewModel?.homeDataList?.records?.first
                        } else {
                            requiredData = viewModel?.homeData
                        }
                        return genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: requiredData?.value?.attributes ?? [:], blurStatus: self.viewModel?.showData ?? false, headerKey: requiredData?.value?.sectionStruct?[indexPath.section - 1].key ?? "")
                    }
                    if viewModel?.isMultipleInputDescriptors() ?? false {
                        var currentSection = 1
                        if let records = viewModel?.homeDataList?.records {
                            for record in records {
                                if record.value?.subType == EBSI_CredentialType.PDA1.rawValue {
                                    let pda1Sections = record.value?.sectionStruct?.count ?? 1
                                    if indexPath.section >= currentSection && indexPath.section < currentSection + pda1Sections {
                                        let pda1SectionIndex = indexPath.section - currentSection

                                        return genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: record.value?.attributes ?? [:], blurStatus: self.viewModel?.showData ?? false, headerKey: record.value?.sectionStruct?[pda1SectionIndex].key ?? "")
                                    }
                                    currentSection += pda1Sections
                                } else {
                                    if indexPath.section == currentSection {
                                        let renderedAttribues = EBSIWallet.shared.getEBSI_V2_attributes(section: currentSection, certModel: record)
                                        guard let data = renderedAttribues[safe: indexPath.row] else { return UITableViewCell() }
                                        if EBSIWallet.shared.isBase64(string: data.value ?? "") {
                                            let cell = tableView.dequeueReusableCell(with: ValuesRowImageTableViewCell.self, for: indexPath)
                                            //cell.delegate = self
                                            cell.setData(model: data)
                                            cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
                                            return cell
                                        }
                                        let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                                        cell.setData(model: data, blurStatus: self.viewModel?.showData ?? false)
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
                    } else if viewModel?.homeDataList?.records != nil {
                        history = viewModel?.homeDataList?.records?[safe: indexPath.section - 1]?.value?.EBSI_v2?.attributes ?? []
                    } else {
                        history = EBSIWallet.shared.getEBSI_V2_attributes(section: indexPath.section - 1, history: viewModel?.history?.value?.history)
                    }
                } else if  viewModel?.history?.value?.history?.certSubType == EBSI_CredentialType.PDA1.rawValue  {
                    var requiredData: SearchItems_CustomWalletRecordCertModel?
                    if viewModel?.homeData == nil {
                        requiredData = viewModel?.homeDataList?.records?.first
                    } else {
                        requiredData = viewModel?.homeData
                    }
                    return genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: requiredData?.value?.attributes ?? [:], blurStatus: self.viewModel?.showData ?? false, headerKey: requiredData?.value?.sectionStruct?[indexPath.section - 1].key ?? "")
                }
                let sortedArry = history.sorted {
                    ($0.name ?? "") < ($1.name ?? "")
                }
                if let data = sortedArry[safe: indexPath.row] {
                    if EBSIWallet.shared.isBase64(string: data.value ?? "") {
                        let cell = tableView.dequeueReusableCell(with: ValuesRowImageTableViewCell.self, for: indexPath)
                        cell.setData(model: data)
                        cell.renderUI(index: indexPath.row, tot: history.count )
                        cell.setPadding(padding: 20)
                        //cell.delegate = self
                        if let color = self.viewModel?.history?.value?.history?.display?.textColor {
                            cell.setCredentialBrandingColor(color:  UIColor(hex: color))
                        }
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                        cell.setData(model: data, blurStatus: self.viewModel?.showData ?? false)
                        cell.renderUI(index: indexPath.row, tot: history.count )
                        cell.setPadding(padding: 20)
                        if let textColor = self.viewModel?.history?.value?.history?.display?.textColor {
                            cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
                        }
                        cell.arrangeStackForDataAgreement()
                        return cell
                    }
                }
                return UITableViewCell()
            }
        case .receiptHistory(model: let model):
            switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCell(with: OverViewTableViewCell.self, for: indexPath)
                let desc = self.viewModel?.orgInfo?.organisationInfoModelDescription ?? self.viewModel?.history?.value?.history?.connectionModel?.value?.orgDetails?.organisationInfoModelDescription
                cell.desLbl.text = desc
                cell.titleLbl.text = "connection_overview".localizedForSDK()
                return cell
                
            case tableView.numberOfSections - 1:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "certificate_data_agreement_policy".localizedForSDK()
                cell.renderFor = .forwardPolicy
                if viewModel?.history?.value?.history?.dataAgreementModel == nil {
                    cell.renderFor = .inActive
                }
                return cell
                
            default:
                // if it is a pullDataNotification
                if viewModel?.history?.value?.history?.pullDataNotification != nil && tableView.numberOfSections - 2 == indexPath.section {
                    let cell = tableView.dequeueReusableCell(withIdentifier:"NotificationTableViewCell",for: indexPath) as! NotificationTableViewCell
                    let controllerDetails = viewModel?.history?.value?.history?.pullDataNotification?.controllerDetails
                    cell.certName.text =  controllerDetails?.organisationName ?? ""
                    cell.notificationType.text = controllerDetails?.location
                    let dateFormat = DateFormatter.init()
                    dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
                    if let notifDate = dateFormat.date(from: viewModel?.history?.value?.history?.date ?? "") {
                        cell.time.text = notifDate.timeAgoDisplay()
                    }
                    UIApplicationUtils.shared.setRemoteImageOn(cell.orgImage, url: controllerDetails?.logoImageURL ?? "")
                    cell.configForPullDataNotification()
                    cell.selectionStyle = .none
                    return cell
                }
                let dataSection = indexPath.section - 1
                let dateFormat = DateFormatter.init()
                dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
                dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
                let time = dateFormat.date(from: viewModel?.history?.value?.history?.date ?? "")
                return receiptTableView(tableView, cellForRowAt: IndexPath.init(row: indexPath.row, section: dataSection), model: model, blurStatus: self.viewModel?.showData ?? false)
            }
            
        case .genericCard(model: let data):
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(with: OverViewTableViewCell.self, for: indexPath)
                cell.desLbl.text = "data_by_choosing_accept_you_agree_to_add_the_data_to_your_data_wallet".localize
                cell.titleLbl.text = "connection_overview".localizedForSDK().localizedUppercase
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "data_remove_data_card".localizedForSDK()
                cell.renderFor = .delete
                return cell
            default:
                let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                let index = indexPath.row - 1
                cell.setDataGeneral(model: data, index: index, blurStatus: self.viewModel?.showData ?? false)
                cell.renderUI(index: index, tot: 2)
                return cell
            }
        case .EBSI:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(with: OverViewTableViewCell.self, for: indexPath)
                let desc = self.viewModel?.orgInfo?.organisationInfoModelDescription ?? self.viewModel?.connectionModel?.value?.orgDetails?.organisationInfoModelDescription
                if desc?.isEmpty ?? true {
                    let cell = UITableViewCell()
                    cell.backgroundColor = .clear
                    return cell
                }
                cell.desLbl.text = desc
                cell.titleLbl.text = "connection_overview".localizedForSDK()
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "welcome_my_shared_data".localizedForSDK()
                cell.renderFor = .forward
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "connection_third_party_data_sharing".localizedForSDK()
                cell.renderFor = .forward
                if (viewModel?.connectionModel?.value?.isThirdPartyShareSupported != "true"){
                    cell.contentView.alpha = 0.5
                    cell.isUserInteractionEnabled = false
                } else {
                    cell.contentView.alpha = 1
                    cell.isUserInteractionEnabled = true
                }
                return cell
            case 3:
//                let cell = tableView.dequeueReusableCell(with: BlurredTextTableViewCell.self, for: indexPath)
//                cell.isUserInteractionEnabled = true
//                cell.didValueLabel.isBlurring = !self.viewModel!.showData
//                cell.configureData(didText: (EBSIWallet.shared.DIDforWUA ?? viewModel?.connectionModel?.tags?.myDid) ?? "")
//                return cell
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "data_remove_organisation".localizedForSDK()
                cell.renderFor = .delete
                return cell
            default:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "data_remove_organisation".localizedForSDK()
                cell.renderFor = .delete
                return cell
            }
        case .orgDetail:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(with: OverViewTableViewCell.self, for: indexPath)
                let desc = self.viewModel?.orgInfo?.organisationInfoModelDescription ?? self.viewModel?.connectionModel?.value?.orgDetails?.organisationInfoModelDescription
                cell.desLbl.text = desc
                cell.titleLbl.text = "connection_overview".localizedForSDK()
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "welcome_my_shared_data".localizedForSDK()
                cell.renderFor = .forward
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "connection_third_party_data_sharing".localizedForSDK()
                cell.renderFor = .forward
                if (viewModel?.connectionModel?.value?.isThirdPartyShareSupported != "true"){
                    cell.contentView.alpha = 0.5
                    cell.isUserInteractionEnabled = false
                } else {
                    cell.contentView.alpha = 1
                    cell.isUserInteractionEnabled = true
                }
                return cell
            case 3:
//                let cell = tableView.dequeueReusableCell(with: BlurredTextTableViewCell.self, for: indexPath)
//                cell.isUserInteractionEnabled = true
//                cell.didValueLabel.isBlurring = !self.viewModel!.showData
//                cell.configureData(didText: (EBSIWallet.shared.DIDforWUA ?? viewModel?.connectionModel?.tags?.myDid) ?? "")
//                return cell
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "data_remove_organisation".localizedForSDK()
                cell.renderFor = .delete
                return cell
            default:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "data_remove_organisation".localizedForSDK()
                cell.renderFor = .delete
                return cell
            }
        default:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(with: OverViewTableViewCell.self, for: indexPath)
                let desc = self.viewModel?.orgInfo?.organisationInfoModelDescription ?? self.viewModel?.connectionModel?.value?.orgDetails?.organisationInfoModelDescription
                cell.desLbl.text = desc
                cell.titleLbl.text = "connection_overview".localizedForSDK()
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "welcome_my_shared_data".localize
                cell.renderFor = .forward
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "connection_third_party_data_sharing".localize
                cell.renderFor = .forward
                if (viewModel?.connectionModel?.value?.isThirdPartyShareSupported != "true"){
                    cell.contentView.alpha = 0.5
                    cell.isUserInteractionEnabled = false
                } else {
                    cell.contentView.alpha = 1
                    cell.isUserInteractionEnabled = true
                }
                return cell
            default:
                let cell = tableView.dequeueReusableCell(with: RemoveBtnTableViewCell.self, for: indexPath)
                cell.title = "data_remove_organisation".localize
                cell.renderFor = .delete
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.viewModel?.pageDelegate?.tappedRow(index: indexPath)
    }
}

//extension OrganizationDetailViewController: ValuesRowImageTableViewCellDelegate {
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

