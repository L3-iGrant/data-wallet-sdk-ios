//
//  CirtificateViewController+TableView.swift
//  dataWallet
//
//  Created by sreelekh N on 07/01/22.
//

import Foundation
import UIKit
extension CertificateViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch pageType {
        case .passport:
            return passportTableView(tableView, cellForRowAt: indexPath)
        case .aadhar:
            return aadharTableView(tableView, cellForRowAt: indexPath)
        case .covid:
            return covidTableView(tableView, cellForRowAt: indexPath)
        case .pkPass:
            return pKPassTableView(tableView, cellForRowAt: indexPath)
        case .general:
            return generalTableView(tableView, cellForRowAt: indexPath)
        case .issueReceipt:
            return receiptTableView(tableView, cellForRowAt: indexPath, model: viewModel.receipt?.receiptModel, blurStatus: showValues)
        case .multipleTypeCards:
            return UITableViewCell()
        case .pwa(isScan: let isScan):
            return UITableViewCell()
        case .photoId(isScan: let isScan):
            return photoIDTableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch pageType {
        case .passport:
            return passportNumberOfRowsInSection(section: section)
        case .aadhar:
            return aadharNumberOfRowsInSection(section: section)
        case .covid:
            return covidNumberOfRowsInSection(section: section)
        case .pkPass:
            return pKPassNumberOfRowsInSection(section: section)
        case .general:
            return generalViewNumberOfRowsInSection(section: section)
        case .issueReceipt:
            return receiptViewNumberOfRowsInSection(section: section, model: viewModel.receipt?.receiptModel)
        case .multipleTypeCards:
            return 0
        case .pwa(isScan: let isScan):
            return 0
        case .photoId(isScan: let isScan):
            return phptoIDNumberOfRowsInSection(section: section)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch pageType {
        case .passport:
            return passportNumberOfSections()
        case .aadhar:
            return aadharNumberOfSections()
        case .covid:
            return covidNumberOfSections()
        case .pkPass(let isScan):
            return pKPassNumberOfSections(isScan: isScan)
        case .general(let isScan):
            return generalViewNumberOfSections(isScan: isScan)
        case .issueReceipt(mode: let mode):
            return receiptViewNumberOfSections(mode: mode)
        case .multipleTypeCards(isScan: let isScan):
            return 0
        case .pwa(isScan: let isScan):
            return 0
        case .photoId(isScan: let isScan):
            return photoIDNumberOfSections(isScan: isScan)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch pageType {
        case .passport:
            return passportViewForHeaderInSection(section: section)
        case .aadhar:
            return aadharViewForHeaderInSection(section: section)
        case .covid:
            return covidViewForHeaderInSection(section: section)
        case .pkPass:
            return pKPassViewForHeaderInSection(section: section)
        case .general:
            return generalViewForHeaderInSection(section: section)
        case .issueReceipt:
            return receiptViewForHeaderInSection(section: section, model: viewModel.receipt?.receiptModel)
        case .multipleTypeCards:
            return nil
        case .pwa(isScan: let isScan):
            return nil
        case .photoId(isScan: let isScan):
            return photoIDViewForHeaderInSection(section: section)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch pageType {
        case .passport:
            return passportHeightForHeaderInSection(section: section)
        case .aadhar:
            return aadharHeightForHeaderInSection(section: section)
        case .covid:
            return covidHeightForHeaderInSection(section: section)
        case .pkPass:
            return pKPassHeightForHeaderInSection(section: section)
        case .general:
            return generalViewHeightForHeaderInSection(section: section)
        case .issueReceipt:
            return receiptViewHeightForHeaderInSection(section: section)
        case .multipleTypeCards:
            return 0.0
        case .pwa(isScan: let isScan):
            return 0.0
        case .photoId(isScan: let isScan):
            return photoIDHeightForHeaderInSection(section: section)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch pageType {
        case .passport(let isScan):
            return passportHeightForFooterInSection(isScan: isScan, section: section)
        case .aadhar(isScan: let isScan):
            return aadharHeightForFooterInSection(isScan: isScan, section: section)
        case .covid(isScan: let isScan):
            return covidHeightForFooterInSection(isScan: isScan, section: section)
        case .pkPass(isScan: let isScan):
            return pKPassHeightForFooterInSection(isScan: isScan, section: section)
        case .general(isScan: let isScan):
            return generalViewHeightForFooterInSection(isScan: isScan, section: section)
        case .issueReceipt:
            return receiptViewHeightForHeaderInSection(section: section)
        case .multipleTypeCards(isScan: let isScan):
            return 0.0
         case .pwa(isScan: let isScan):
             return 0.0
         case .photoId(isScan: let isScan):
             return photoIDHeightForFooterInSection(isScan: isScan, section: section)
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch pageType {
        case .passport(let isScan):
            return passportViewForFooterInSection(isScan: isScan, section: section)
        case .aadhar(let isScan):
            return aadharViewForFooterInSection(isScan: isScan, section: section)
        case .covid(isScan: let isScan):
            return covidViewForFooterInSection(isScan: isScan, section: section)
        case .pkPass(isScan: let isScan):
            return pKPassViewForFooterInSection(isScan: isScan, section: section)
        case .general(isScan: let isScan):
            if let subType = viewModel.general?.certModel?.value?.subType, subType.contains("WALLET UNIT ATTESTATION") {
                return nil
            } else {
                return generalViewForFooterInSection(isScan: isScan, section: section)
            }
        case .issueReceipt(mode: let mode):
            return receiptViewForFooterInSection(mode: mode, section: section, deleteAction: deleteAction)
        case .multipleTypeCards(isScan: let isScan):
            return nil
        case .pwa(isScan: let isScan):
            return nil
        case .photoId(isScan: let isScan):
            return photoIDViewForFooterInSection(isScan: isScan, section: section)
        }
    }
}
