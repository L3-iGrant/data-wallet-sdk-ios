//
//  CertificateViewController+GenericAttributeStructure.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 16/02/23.
//

import Foundation
import UIKit

extension CertificateViewController: GenericAttributeStructureTableView{
}
extension CertificatePreviewViewController: GenericAttributeStructureTableView{
}

extension CertificatePreviewBottomSheet: GenericAttributeStructureTableView{
}

protocol GenericAttributeStructureTableView{
    func registerCellsForGenericAttributeStructure(tableView: UITableView)
    func genericAttributeStructureViewForFooterInSection(mode: CredentialMode, section: Int, deleteAction: @escaping () -> ()) -> UIView?
    func genericAttributeStructureViewHeightForFooterInSection(mode: CredentialMode, section: Int) -> CGFloat
    func genericAttributeStructureViewHeightForHeaderInSection(section: Int) -> CGFloat
    func genericAttributeStructureViewForHeaderInSection(section: Int, model: DWSection?, textColor: String?) -> UIView?
    func genericAttributeStructureViewNumberOfSections(mode: CredentialMode,headers: [DWSection]) -> Int
    func genericAttributeStructureViewNumberOfRowsInSection(section: Int, model: OrderedDictionary<String,DWAttributesModel>?, headerKey: String) -> Int
    func genericAttributeStructureTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: OrderedDictionary<String,DWAttributesModel>,blurStatus: Bool,headerKey: String, textColor: String?) -> UITableViewCell
}

extension GenericAttributeStructureTableView {
    
    func registerCellsForGenericAttributeStructure(tableView: UITableView) {
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
        tableView.register(cellType: PhotoIdWithImageCell.self)
    }
    
    func genericAttributeStructureViewForFooterInSection(mode: CredentialMode, section: Int, deleteAction: @escaping () -> ()) -> UIView? {
        if mode == .view && section == 5 {
            let view = RemoveBtnVew()
            view.tapAction = deleteAction
            view.value = "Remove data card".localizedForSDK()
            return view
        }
        return nil
    }
    
    func genericAttributeStructureViewHeightForFooterInSection(mode: CredentialMode, section: Int) -> CGFloat {
        if mode == .view && section == 5 {
            return 60
        }
        return CGFloat.leastNormalMagnitude
    }
    
    func genericAttributeStructureViewHeightForHeaderInSection(section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func genericAttributeStructureViewForHeaderInSection(section: Int, model: DWSection?, textColor: String? = "") -> UIView?{
        var certName = model?.title ?? ""
        let view = GeneralTitleView.init()
        view.value = certName
        view.btnNeed = false
        if let textColor = textColor, !textColor.isEmpty {
            view.lbl.textColor = UIColor(hex: textColor)
        }
        view.layoutIfNeeded()
        return view
    }
    
    func genericAttributeStructureViewNumberOfSections(mode: CredentialMode, headers: [DWSection]) -> Int {
        return headers.count
    }
    
    func genericAttributeStructureViewNumberOfRowsInSection(section: Int, model: OrderedDictionary<String,DWAttributesModel>?, headerKey: String) -> Int{
        let key = headerKey
        let numberOfCells = model?.orderedValues.filter { e in
            e.parent == key
        }
        return numberOfCells?.count ?? 0
    }
    
    func genericAttributeStructureTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, model: OrderedDictionary<String,DWAttributesModel>,blurStatus: Bool,headerKey: String, textColor: String? = "") -> UITableViewCell {
        var attrArray: [IDCardAttributes] = []
        let key = headerKey
        let grouped = model.orderedValues.filter { e in
            e.parent == key
        }
        grouped.forEach { e in
            attrArray.append(IDCardAttributes(name: e.label, value: e.value))
        }
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
