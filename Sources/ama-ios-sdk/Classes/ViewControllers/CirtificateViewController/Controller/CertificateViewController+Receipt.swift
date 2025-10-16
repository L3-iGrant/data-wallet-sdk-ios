//
//  CertificateViewController+receipt.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 27/01/23.
//

import Foundation
import UIKit

extension CertificateViewController: ReceiptTableView{
}



protocol ReceiptTableView{
    func registerCellsForReceipt(tableView: UITableView)
    func receiptViewForFooterInSection(mode: CredentialMode, section: Int, deleteAction: @escaping () -> ()) -> UIView?
    func receiptViewHeightForFooterInSection(mode: CredentialMode, section: Int) -> CGFloat
    func receiptViewHeightForHeaderInSection(section: Int) -> CGFloat
    func receiptViewForHeaderInSection(section: Int, model: ReceiptCredentialModel?) -> UIView?
    func receiptViewNumberOfSections(mode: CredentialMode) -> Int
    func receiptViewNumberOfRowsInSection(section: Int, model: ReceiptCredentialModel?) -> Int
    func receiptTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ReceiptCredentialModel?,blurStatus: Bool) -> UITableViewCell
}

extension ReceiptTableView {
    
    func registerCellsForReceipt(tableView: UITableView) {
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
        tableView.register(cellType: ReceiptTableViewCell.self)
    }
    
    func receiptViewForFooterInSection(mode: CredentialMode, section: Int, deleteAction: @escaping () -> ()) -> UIView? {
        if mode == .view && section == 1 {
            let view = RemoveBtnVew()
            view.tapAction = deleteAction
            view.value = "Remove data card".localizedForSDK()
            return view
        }
        return nil
    }
    
    func receiptViewHeightForFooterInSection(mode: CredentialMode, section: Int) -> CGFloat {
        if mode == .view && section == 1 {
            return 60
        }
        return CGFloat.leastNormalMagnitude
    }
    
    func receiptViewHeightForHeaderInSection(section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func receiptViewForHeaderInSection(section: Int, model: ReceiptCredentialModel?) -> UIView? {
        var certName = ""
        switch section {
        case 0: certName = "INVOICE" + ": " + (model?.iD ?? "")
        case 1: certName = "CUSTOMER DETAILS"
        default:
            break
        }
        let view = GeneralTitleView.init()
        view.value = certName
        view.btnNeed = false
        view.layoutIfNeeded()
        return view
    }
    
    func receiptViewNumberOfSections(mode: CredentialMode) -> Int {
        return 2
    }
    
    func receiptViewNumberOfRowsInSection(section: Int, model: ReceiptCredentialModel?) -> Int {
        switch section {
        case 0: return (model?.invoiceLine?.count ?? 0) + 2
        case 1: return 4
        default:
            return 0
        }
    }
    
    func receiptTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: ReceiptCredentialModel?,blurStatus: Bool) -> UITableViewCell {
        if indexPath.section == 0 {
            var attrArray:[InvoiceLine] = []

            attrArray = model?.invoiceLine ?? []
            //Header
            attrArray.insert(InvoiceLine.init(iD: nil, invoicedQuantity: nil, lineExtensionAmount: nil, item: nil, price: nil), at: 0)
            //Total
            attrArray.append(InvoiceLine.init(iD: nil, invoicedQuantity: nil, lineExtensionAmount: nil, item: nil, price: nil))
            guard let data = attrArray[safe: indexPath.row] else { return UITableViewCell()}
            let cell = tableView.dequeueReusableCell(with: ReceiptTableViewCell.self, for: indexPath)
            if indexPath.row == 0 {
                cell.setHeader(blurStatus: blurStatus)
            } else if indexPath.row == (attrArray.count - 1){
                cell.setTotal(total: "\(model?.legalMonetaryTotal?.chargeTotalAmount ?? 0)",currency: model?.documentCurrencyCode ?? "EUR", blurStatus: blurStatus)
            } else {
                cell.setData(model: data, blurStatus: blurStatus, currency: model?.documentCurrencyCode ?? "EUR")
            }
           
            cell.renderUI(index: indexPath.row, tot: attrArray.count)
            cell.layoutIfNeeded()
            return cell
        } else {
            var attrArray:[IDCardAttributes] = []
            attrArray = self.getAttributeArray(model: model)
            let renderedAttribues = attrArray.createAndFindNumberOfLines()
            guard let data = renderedAttribues[safe: indexPath.row] else { return UITableViewCell()}
            if data.type == .image {
                let cell = tableView.dequeueReusableCell(with: ValuesRowImageTableViewCell.self, for: indexPath)
                cell.setData(model: data)
                cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
                return cell
            }
            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                cell.setData(model: data, blurStatus: blurStatus)
                cell.renderUI(index: indexPath.row, tot: renderedAttribues.count)
            cell.arrangeStackForDataAgreement()
            cell.layoutIfNeeded()
            return cell
        }
    }
    
    func getAttributeArray(model: ReceiptCredentialModel?) -> [IDCardAttributes]{
        var attrArray:[IDCardAttributes] = []
        attrArray.append(IDCardAttributes(name: "Full Name", value: model?.accountingCustomerParty?.party?.partyName?.name ?? "", schemeID: ""))
        attrArray.append(IDCardAttributes(name: "Issued", value: model?.issueDate ?? "", schemeID: ""))
        attrArray.append(IDCardAttributes(name: "Payment Terms", value: model?.paymentTerms?.note ?? "", schemeID: ""))
        
        let street = model?.accountingCustomerParty?.party?.postaladdress?.streetName ?? ""
        let city = model?.accountingCustomerParty?.party?.postaladdress?.cityName ?? ""
        let country = model?.accountingCustomerParty?.party?.postaladdress?.country?.name ?? ""
        let pin = model?.accountingCustomerParty?.party?.postaladdress?.postalZone ?? ""
        let address = street + ", " + city + "\n" + pin + ", " + country
        attrArray.append(IDCardAttributes(name: "Address", value: address, schemeID: ""))
        return attrArray
    }
}
