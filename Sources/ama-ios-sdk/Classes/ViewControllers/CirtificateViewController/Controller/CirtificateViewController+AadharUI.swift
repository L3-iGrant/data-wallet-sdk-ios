//
//  CirtificateViewController+AadharUI.swift
//  dataWallet
//
//  Created by sreelekh N on 08/01/22.
//

import Foundation
import UIKit

extension CertificateViewController {
  
    func aadharViewForFooterInSection(isScan: Bool, section: Int) -> UIView? {
        guard !isScan else {
            return nil
        }
        let view = RemoveBtnVew()
        view.tapAction = { [weak self] in
            self?.deleteAction()
        }
        view.value = "Remove data card".localizedForSDK()
        return view
    }
    
    func aadharHeightForFooterInSection(isScan: Bool, section: Int) -> CGFloat {
        guard !isScan else {
            return CGFloat.leastNormalMagnitude
        }
        return section == 0 ? CGFloat.leastNormalMagnitude : 60
    }
    
    func aadharHeightForHeaderInSection(section: Int) -> CGFloat {
        switch section {
        case 0:
            return 120
        default:
            return 45
        }
    }
    
    func aadharViewForHeaderInSection(section: Int) -> UIView? {
        switch section {
        case 0:
            let view = HeaderSingleImageTile()
            view.image = self.viewModel.aadhar?.userImage ?? "placeholder".getImage()
            return view
        default:
            let view = GeneralTitleView()
            view.btnNeed = false
            view.value = "AADHAR DETAILS".localizedForSDK()
            return view
        }
    }
    
    func aadharNumberOfSections() -> Int {
        return 2
    }
    
    func aadharNumberOfRowsInSection(section: Int) -> Int {
        switch section {
        case 0:
            return 0
        default:
            return self.viewModel.aadhar?.aadharDetails?.count ?? 0
        }
    }
    
    func aadharTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
        if let data = self.viewModel.aadhar?.aadharDetails?[safe: indexPath.row] {
            cell.setData(model: data, blurStatus: showValues)
            cell.renderUI(index: indexPath.row, tot: self.viewModel.aadhar?.aadharDetails?.count ?? 0)
        }
        cell.layoutIfNeeded()
        return cell
    }
}
