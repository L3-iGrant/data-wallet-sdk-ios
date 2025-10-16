//
//  ThirdPartyGroupViewController+TableView.swift
//  dataWallet
//
//  Created by sreelekh N on 07/09/22.
//

import UIKit
extension ThirdPartyGroupViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.viewModel.responseData.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 46
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = SettingsHeader()
        view.updateForThirdParty()
        let segment = self.viewModel.responseData[safe: section]
        view.title = segment?.purpose?.capitalized ?? ""
        let switchState = segment?.toggleStatus ?? false
        view.toggle.setOn(switchState, animated: true)
        view.toggle.addTarget(self, action: #selector(mainToggleUpdated(_:)), for: .valueChanged)
        view.infoButton.addTarget(self, action:  #selector(infoButtonTapped(_:)), for: .touchUpInside)
        view.toggle.tag = section
        view.infoButton.tag = section
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let arr = self.viewModel.responseData[safe: section]
        let val = arr?.value
        return val?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: SettingsTableViewCell.self, for: indexPath)
        let mainInstanceToggleStatus = self.viewModel.responseData[safe: indexPath.section]?.toggleStatus ?? false
        if let data = self.viewModel.responseData[safe: indexPath.section]?.value {
            cell.setThirdPartyData(data: data, row: indexPath.row)
        }
        cell.toggleTapped = { [weak self] in
            Task {
                let result = await ThirdPartyDataSharing.shared.updateDDAPreferenceUsingOrgID(orgID: self?.viewModel.connectionModel?.value?.orgDetails?.orgId ?? "", data: self?.viewModel.responseData[indexPath.section].value?[indexPath.row])
                if result.0 ?? false {
                    guard let dus = result.1 else { return }
                    self?.viewModel.responseData[indexPath.section].value?[indexPath.row] = dus
                    guard let updatedData = self?.viewModel.responseData[indexPath.section] else { return }
                    if let main = self?.viewModel.responseMainCarrier.firstIndex(where: { $0.id == updatedData.id }) {
                        self?.viewModel.responseMainCarrier[main].value = updatedData.value
                    }
                }
            }
        }
        cell.tag = indexPath.row
        if (!mainInstanceToggleStatus){
            cell.alpha = 0.6
            cell.toggle.isEnabled = false
        } else {
            cell.alpha = 1
            cell.toggle.isEnabled = true
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.prepareForReuse()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

