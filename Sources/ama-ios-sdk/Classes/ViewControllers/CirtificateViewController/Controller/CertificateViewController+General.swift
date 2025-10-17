//
//  CertificateViewController+General.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 22/08/22.
//

import Foundation
import UIKit
extension CertificateViewController {
    
    func generalViewForFooterInSection(isScan: Bool, section: Int) -> UIView? {
        guard !isScan else {
            return nil
        }
        if section == generalViewNumberOfSections() - 1 {
            let view = RemoveBtnVew()
            view.tapAction = { [weak self] in
                self?.deleteAction()
            }
            if let color = viewModel.general?.certModel?.value?.textColor {
                view.layerColor = UIColor(hex: color)
            }
            view.value = "data_remove_data_card".localizedForSDK()
            return view
        } else {
            return nil
        }
    }
    
    func generalViewHeightForFooterInSection(isScan: Bool, section: Int) -> CGFloat {
        guard !isScan else {
            return CGFloat.leastNormalMagnitude
        }
        if viewModel.general?.isEBSI_diploma() ?? false{
            return section == 2 ? 60 : 10
        }
        if viewModel.general?.certModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue || viewModel.general?.certModel?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue{
            return section == generalViewNumberOfSections() - 1 ? 65 :CGFloat.leastNormalMagnitude
        }
        return section == generalViewNumberOfSections() - 1 ? 65 :CGFloat.leastNormalMagnitude
    }
    
    func generalViewHeightForHeaderInSection(section: Int) -> CGFloat {
        if section == generalViewNumberOfSections() - 1 {
            return 0
        } else {
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
    }
    
    func calculateHeightForText(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func generalViewForHeaderInSection(section: Int) -> UIView? {
        if section == generalViewNumberOfSections() - 1 {
            return nil
        } else {
            var certName = ""
            if viewModel.general?.isEBSI() ?? false{
                if viewModel.general?.isEBSI_diploma() ?? false{
                    switch section{
                    case 0: certName = "Identifier".uppercased()
                    case 1: certName = "Specified by".uppercased()
                    case 2: certName = "was awarded by".uppercased()
                    default: certName = "Identifier".uppercased()
                    }
                } else if viewModel.general?.certModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue  || viewModel.general?.certModel?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue{
                    return genericAttributeStructureViewForHeaderInSection(section: section, model: viewModel.general?.certModel?.value?.sectionStruct?[section], textColor: viewModel.general?.certModel?.value?.textColor)
                } else {
                    certName = viewModel.general?.certModel?.value?.searchableText ?? ""
                }
            } else {
                let schemeSeperated = viewModel.general?.certDetail?.value?.schemaID?.split(separator: ":")
                certName = "\(schemeSeperated?[2] ?? "")".uppercased()
            }
            certificateName = certName
            let view = GeneralTitleView.init()
            view.value = certName
            if let color = viewModel.general?.certModel?.value?.textColor {
                view.lbl.textColor = UIColor(hex: color)
            }
            view.btnNeed = false
            return view
        }
    }
    
    func generalViewNumberOfSections(isScan: Bool = false) -> Int {
        if viewModel.general?.isEBSI_diploma() ?? false {
            return isScan ? 3 : 4
        } else if viewModel.general?.certModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue || viewModel.general?.certModel?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue{
            return isScan ? genericAttributeStructureViewNumberOfSections(mode: .view, headers: viewModel.general?.certModel?.value?.sectionStruct ?? []) : genericAttributeStructureViewNumberOfSections(mode: .view, headers: viewModel.general?.certModel?.value?.sectionStruct ?? []) + 1
        } else {
            return isScan ? 1 : 2
        }
    }
    
    func generalViewNumberOfRowsInSection(section: Int) -> Int {
        if section == generalViewNumberOfSections() - 1 {
            return 1
        }
        if viewModel.general?.isEBSI() ?? false {
            if viewModel.general?.certModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue {
                return genericAttributeStructureViewNumberOfRowsInSection(section: section, model: viewModel.general?.certModel?.value?.attributes, headerKey: viewModel.general?.certModel?.value?.sectionStruct?[section].key ?? "")
            } else if viewModel.general?.certModel?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
                if viewModel.general?.certModel?.value?.sectionStruct?[section].type == "photoIDwithImageBadge" {
                    return 1
                } else {
                    return genericAttributeStructureViewNumberOfRowsInSection(section: section, model: viewModel.general?.certModel?.value?.attributes, headerKey: viewModel.general?.certModel?.value?.sectionStruct?[section].key ?? "")
                }
            }
            return EBSIWallet.shared.getEBSI_V2_attributes(section: section, certModel: viewModel.general?.certModel).count
        } else if let attributes = viewModel.general?.certModel?.value?.attributes {
            return viewModel.general?.certModel?.value?.attributes?.count ?? 0
        }
        return viewModel.general?.certDetail?.value?.credentialProposalDict?.credentialProposal?.attributes?.count ?? 0
    }
    
    func generalTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == generalViewNumberOfSections() - 1 {
            let cell = tableView.dequeueReusableCell(with: IssuanceTimeTableViewCell.self, for: indexPath)
            let dateFormat = DateFormatter.init()
            if let unixTimestamp = TimeInterval(viewModel.general?.certModel?.value?.addedDate ?? "") {
                let date = Date(timeIntervalSince1970: unixTimestamp)
                dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let dateString = dateFormat.string(from: date)
                let formattedDate = dateFormat.date(from: dateString)
                if let bgColor = viewModel.general?.certModel?.value?.textColor  {
                    cell.setTextColor(colour: UIColor(hex: bgColor) )
                }
                cell.setData(text: formattedDate?.timeAgoDisplay() ?? "", data: viewModel.general?.certModel?.value)
            }
            return cell
        } else {
            var attrArray:[IDCardAttributes] = []
            if viewModel.general?.isEBSI() ?? false {
                if viewModel.general?.certModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue {
                    return genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: viewModel.general?.certModel?.value?.attributes ?? [:], blurStatus: showValues, headerKey: viewModel.general?.certModel?.value?.sectionStruct?[indexPath.section].key ?? "", textColor: viewModel.general?.certModel?.value?.textColor)
                } else if viewModel.general?.certModel?.value?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
                    if viewModel.general?.certModel?.value?.sectionStruct?[indexPath.section].type == "photoIDwithImageBadge" {
                        let cell = tableView.dequeueReusableCell(with: PhotoIdWithImageCell.self, for: indexPath)
                        cell.configureCell(model: viewModel.general?.certModel?.value?.attributes ?? [:], blureStatus: showValues)
                        cell.delegate = self
                        return cell
                    } else {
                        return genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: viewModel.general?.certModel?.value?.attributes ?? [:], blurStatus: showValues, headerKey: viewModel.general?.certModel?.value?.sectionStruct?[indexPath.section].key ?? "", textColor: viewModel.general?.certModel?.value?.textColor)
                    }
                }
                attrArray = EBSIWallet.shared.getEBSI_V2_attributes(section: indexPath.section, certModel: viewModel.general?.certModel)
            } else if let attr = viewModel.general?.certModel?.value?.attributes {
                let grouped = attr.orderedValues
                grouped.forEach { e in
                    attrArray.append(IDCardAttributes(name: e.label, value: e.value))
                }
            } else {
                attrArray = viewModel.general?.certDetail?.value?.credentialProposalDict?.credentialProposal?.attributes?.map({ (item) -> IDCardAttributes in
                    return IDCardAttributes.init(type: CertAttributesTypes.string, name: item.name, value: item.value)
                }) ?? []
            }
            let sortedArry = attrArray.sorted {
                ($0.name ?? "") < ($1.name ?? "")
            }
            let renderedAttribues = sortedArry.createAndFindNumberOfLines()
            guard let data = renderedAttribues[safe: indexPath.row] else { return UITableViewCell()}
            if EBSIWallet.shared.isBase64(string: data.value ?? "") {
                let cell = tableView.dequeueReusableCell(with: ValuesRowImageTableViewCell.self, for: indexPath)
                cell.setData(model: data)
                cell.delegate = self
                cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
                if let color = viewModel.general?.certModel?.value?.textColor {
                    cell.setCredentialBrandingColor(color:  UIColor(hex: color))
                }
                return cell
            }
            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
            cell.setData(model: data, blurStatus: showValues)
            cell.renderUI(index: indexPath.row, tot: renderedAttribues.count )
            cell.arrangeStackForDataAgreement()
            if let color = viewModel.general?.certModel?.value?.textColor {
                cell.renderForCredentialBranding(clr: UIColor(hex: color) )
            }
            cell.layoutIfNeeded()
            return cell
        }
    }
}

extension CertificateViewController: ValuesRowImageTableViewCellDelegate {
    
    func showImageDetail(image: UIImage?) {
        if let vc = ShowQRCodeViewController().initialize() as? ShowQRCodeViewController {
            vc.QRCodeImage = image
            self.present(vc: vc, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
        }
    }
    
    
}

