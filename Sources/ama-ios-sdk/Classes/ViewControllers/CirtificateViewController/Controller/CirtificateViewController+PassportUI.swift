//
//  CirtificateViewController+PassportUI.swift
//  dataWallet
//
//  Created by sreelekh N on 07/01/22.
//

import Foundation
import UIKit

extension CertificateViewController {
   
    func passportViewForFooterInSection(isScan: Bool, section: Int) -> UIView? {
        guard !isScan else {
            return nil
        }
        switch section {
        case 2:
            let view = RemoveBtnVew()
            view.tapAction = { [weak self] in
                self?.deleteAction()
            }
            view.value = "Remove data card".localizedForSDK()
            return view
        default:
            return nil
        }
    }
    
    func passportHeightForFooterInSection(isScan: Bool, section: Int) -> CGFloat {
        guard !isScan else {
            return CGFloat.leastNormalMagnitude
        }
        return section == 2 ? 60 : CGFloat.leastNormalMagnitude
    }
    
    func passportHeightForHeaderInSection(section: Int) -> CGFloat {
        switch section {
        case 0:
            return 160
        default:
            return 8
        }
    }
    
    func passportViewForHeaderInSection(section: Int) -> UIView? {
        switch section {
        case 0:
            let header = PassportHeaderView()
            let headerimg = UIApplicationUtils.shared.convertBase64StringToImage(imageBase64String: viewModel.passport.passportModel?.profileImage?.value ?? "")
            header.imgView.image = headerimg
            return header
        default:
            return nil
        }
    }
    
    func passportNumberOfSections() -> Int {
      return (self.viewModel.passport.passportSections.count) + 1
    }
    
    func passportNumberOfRowsInSection(section: Int) -> Int {
        switch section {
        case 2:
            return 1
        default:
            return self.viewModel.passport.passportSections[section].count
        }
    }
    
    func photoIDTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(with: PhotoIdWithImageCell.self, for: indexPath)
            cell.delegate = self
            cell.configureCell(portait: viewModel.photoID?.photoIDCredential?.iso23220?.portrait ?? "", ageOver18: viewModel.photoID?.photoIDCredential?.iso23220?.ageOver18 ?? false, blureStatus: showValues)
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(with: IssuanceTimeTableViewCell.self, for: indexPath)
            let dateFormat = DateFormatter.init()
            if let unixTimestamp = TimeInterval(viewModel.addedDate ) {
                let date = Date(timeIntervalSince1970: unixTimestamp)
                dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let dateString = dateFormat.string(from: date)
                if let color = viewModel.photoID?.display?.textColor {
                    cell.setTextColor(colour: UIColor(hex: color))
                }
                let formattedDate = dateFormat.date(from: dateString)
                cell.setData(text: formattedDate?.timeAgoDisplay() ?? "")
            }
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(with: PhotoIDIssuerDetailsCell.self, for: indexPath)
            cell.configureCell(value: viewModel.photoID?.orgInfo)
            if let color = viewModel.photoID?.display?.textColor {
                cell.renderForCredebtialBranding(clr: UIColor(hex: color))
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
            if let data = self.viewModel.photoID?.photoIdSections[safe: indexPath.section]?[indexPath.row] {
                cell.setPassportData(model: data, blurStatus: showValues)
                cell.renderUI(index: indexPath.row, tot: self.viewModel.photoID?.photoIdSections[indexPath.section].count ?? 0)
                if let color = viewModel.photoID?.display?.textColor {
                    cell.renderForCredentialBranding(clr: UIColor(hex: color) )
                }
            }
            cell.layoutIfNeeded()
            return cell
        }
    }
    
    func photoIDViewForFooterInSection(isScan: Bool, section: Int) -> UIView? {
        guard !isScan else {
            return nil
        }
        if viewModel.photoID?.orgInfo != nil {
            if section == 5 {
                let view = RemoveBtnVew()
                view.tapAction = { [weak self] in
                    self?.deleteAction()
                }
                view.value = "data_remove_data_card".localizedForSDK()
                if let color = viewModel.photoID?.display?.textColor {
                    view.layerColor = UIColor(hex: color)
                }
                return view
            } else {
                return nil
            }
        } else {
            if section == 4 {
                let view = RemoveBtnVew()
                view.tapAction = { [weak self] in
                    self?.deleteAction()
                }
                view.value = "data_remove_data_card".localizedForSDK()
                return view
            } else {
                return nil
            }
        }
    }
    
    func photoIDHeightForHeaderInSection(section: Int) -> CGFloat {
        switch section {
        case 1, 5:
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
        default:
            return 0
        }
    }
    
    func photoIDHeightForFooterInSection(isScan: Bool, section: Int) -> CGFloat {
        guard !isScan else {
            return CGFloat.leastNormalMagnitude
        }
        if viewModel.photoID?.orgInfo != nil {
            if section == 5 {
                return 60
            } else {
                return CGFloat.leastNormalMagnitude
            }
        } else if section == 4 {
            return 60
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func photoIDViewForHeaderInSection(section: Int) -> UIView? {
        switch section {
        case 1, 5:
            let view = GeneralTitleView.init()
            view.value = section == 1 ? "cards_photo_id_detail".localizedForSDK().uppercased() : "issued_by".localizedForSDK().uppercased()
            if let color = viewModel.photoID?.display?.textColor {
                view.lbl.textColor = UIColor(hex: color)
            }
            view.btnNeed = false
            return view
        default:
            return nil
        }
    }
    
    func photoIDNumberOfSections(isScan: Bool) -> Int {
        if isScan {
            return (self.viewModel.photoID?.photoIdSections.count ?? 0)
        } else {
            if self.viewModel.photoID?.orgInfo != nil {
                return (self.viewModel.photoID?.photoIdSections.count ?? 0) + 2
            } else {
                return (self.viewModel.photoID?.photoIdSections.count ?? 0) + 1
            }
        }
    }
    
    func phptoIDNumberOfRowsInSection(section: Int) -> Int {
        switch section {
        case 0,4, 5:
            return 1
        default:
            return self.viewModel.photoID?.photoIdSections[section].count ?? 0
        }
    }
    
    func passportTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 2:
            let cell = tableView.dequeueReusableCell(with: SignImageTableViewCell.self, for: indexPath)
            let signImg = UIApplicationUtils.shared.convertBase64StringToImage(imageBase64String: viewModel.passport.passportModel?.signature?.value ?? "") ?? "NoSign".getImage()
            cell.signImageView.image = signImg
            return cell
        default:
            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
            if let data = self.viewModel.passport.passportSections[safe: indexPath.section]?[indexPath.row] {
                cell.setPassportData(model: data, blurStatus: showValues)
                cell.renderUI(index: indexPath.row, tot: self.viewModel.passport.passportSections[indexPath.section].count)
            }
            cell.layoutIfNeeded()
            return cell
        }
    }
}
