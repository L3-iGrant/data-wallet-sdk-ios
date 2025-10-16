//
//  CirtificateViewController+pKPass.swift
//  dataWallet
//
//  Created by sreelekh N on 08/01/22.
//

import Foundation
import UIKit

extension CertificateViewController {
    
    func pKPassViewForFooterInSection(isScan: Bool, section: Int) -> UIView? {
        guard !isScan else {
            return nil
        }
        let view = RemoveBtnVew()
        view.tapAction = { [weak self] in
            self?.deleteAction()
        }
        view.value = "Remove data card".localizedForSDK()
        view.layerColor = self.viewModel.pkPass?.labelColor
        return view
    }
    
    func pKPassHeightForFooterInSection(isScan: Bool, section: Int) -> CGFloat {
        guard !isScan else {
            return CGFloat.leastNormalMagnitude
        }
        return section == 0 ? CGFloat.leastNormalMagnitude : 60
    }
    
    func pKPassHeightForHeaderInSection(section: Int) -> CGFloat {
        return section == 0 ? 20 : CGFloat.leastNormalMagnitude
    }
    
    func pKPassViewForHeaderInSection(section: Int) -> UIView? {
        return nil
    }
    
    func pKPassNumberOfSections(isScan: Bool) -> Int {
        return 2
    }
    
    func pKPassNumberOfRowsInSection(section: Int) -> Int {
        switch section {
        case 0:
            return self.viewModel.pkPass?.attrArray.count ?? 0
        default:
            return 1
        }
    }
    
    func pKPassTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
            let renderedAttribues = self.viewModel.pkPass?.attrArray.createAndFindNumberOfLines()
            if let data = renderedAttribues?[safe: indexPath.row] {
                cell.setData(model: data, blurStatus: showValues)
                cell.renderUI(index: indexPath.row, tot: renderedAttribues?.count ?? 0)
            }
            if let labelColor = self.viewModel.pkPass?.labelColor {
                cell.renderForPKPass(clr: labelColor)
            }
            cell.layoutIfNeeded()
            return cell
        default:
            let cell = tableView.dequeueReusableCell(with: PKPassQRTableViewCell.self, for: indexPath)
            cell.QRCode.image = viewModel.pkPass?.barCodeImage ?? "iGrant.io_DW_Logo".getImage()
            if let labelColor = viewModel.pkPass?.labelColor {
                cell.renderUI(clr: labelColor)
            }
            cell.button.addTarget(self, action: #selector(showAdditionalDetails), for: .touchUpInside)
            return cell
        }
    }
}
