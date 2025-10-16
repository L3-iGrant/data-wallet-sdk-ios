//
//  SettingsPageViewController+TableView.swift
//  dataWallet
//
//  Created by sreelekh N on 07/09/22.
//

import UIKit
extension SettingsPageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.viewModel.content.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.viewModel.content[section].title.isNotEmpty {
            switch section {
            case 1:
                if isWelcome ?? false {
                    return CGFloat.leastNonzeroMagnitude
                }
            default:
                break
            }
            return 28
        }
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if isWelcome ?? false {
            switch section {
            case 0:
                return CGFloat.leastNonzeroMagnitude
            default: break
            }
        }
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.viewModel.content[section].title.isNotEmpty {
            switch section {
            case 1:
                if isWelcome ?? false {
                    return nil
                }
            default:
                break
            }
            let view = SettingsHeader()
            view.title = self.viewModel.content[section].title
            return view
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isWelcome ?? false {
            switch indexPath.section {
            case 1:
                switch indexPath.row {
                case 0:
                    return CGFloat.leastNonzeroMagnitude
                default: break
                }
            case 2:
                switch indexPath.row {
                case 2:
                    return CGFloat.leastNonzeroMagnitude
                default: break
                }
            case 3:
                switch indexPath.row {
                case 1:
                    return CGFloat.leastNonzeroMagnitude
                default: break
                }
            default: break
            }
        }
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.content[section].content.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: SettingsTableViewCell.self, for: indexPath)
        cell.setData(data: self.viewModel.content[indexPath.section].content[indexPath.row], indexPath: indexPath)
        cell.renderUI(total: self.viewModel.content[indexPath.section].content.count, now: indexPath.row, section: indexPath.section)
        cell.toggleTapped = { [weak self] in
            self?.toggleAction(indexPath: indexPath)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.prepareForReuse()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tapAction(indexPath: indexPath)
    }
}

