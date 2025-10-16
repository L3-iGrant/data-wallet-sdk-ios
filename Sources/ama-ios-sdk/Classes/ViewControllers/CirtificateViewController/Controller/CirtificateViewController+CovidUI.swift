//
//  CirtificateViewController+CovidUI.swift
//  dataWallet
//
//  Created by sreelekh N on 07/01/22.
//

import Foundation
import UIKit

extension CertificateViewController {
    
    func covidViewForFooterInSection(isScan: Bool, section: Int) -> UIView? {
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
    
    func covidHeightForFooterInSection(isScan: Bool, section: Int) -> CGFloat {
        guard !isScan else {
            return CGFloat.leastNormalMagnitude
        }
        return section == 0 ? CGFloat.leastNormalMagnitude : 60
    }
    
    func covidHeightForHeaderInSection(section: Int) -> CGFloat {
        return 45
    }
    
    func covidViewForHeaderInSection(section: Int) -> UIView? {
        let view = GeneralTitleView()
        view.btnNeed = false
        switch section {
        case 0:
            view.value = "Beneficiary Details".localizedForSDK().localizedUppercase
        default:
            view.value = self.viewModel.covid?.certificateType == .EuropianCovid ? "Vaccination Details".localizedForSDK().localizedUppercase : "test_certificate_details".localizedForSDK().localizedUppercase
        }
        return view
    }
    
    func covidNumberOfSections() -> Int {
        return 2
    }
    
    func covidNumberOfRowsInSection(section: Int) -> Int {
        switch section {
        case 0:
            return self.viewModel.covid?.beneficiaryDetails?.count ?? 0
        default:
            return self.viewModel.covid?.vaccinationDetails?.count ?? 0
        }
    }
    
    func covidTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
        switch indexPath.section {
        case 0:
            if let data = self.viewModel.covid?.beneficiaryDetails?[safe: indexPath.row] {
                cell.setData(model: data, blurStatus: showValues)
                cell.renderUI(index: indexPath.row, tot: self.viewModel.covid?.beneficiaryDetails?.count ?? 0)
            }
        default:
            if let data = self.viewModel.covid?.vaccinationDetails?[safe: indexPath.row] {
                cell.setData(model: data, blurStatus: showValues)
                cell.renderUI(index: indexPath.row, tot: self.viewModel.covid?.vaccinationDetails?.count ?? 0)
            }
        }
        cell.layoutIfNeeded()
        return cell
    }
}
