//
//  ActionSheetViewController+TableView.swift
//  dataWallet
//
//  Created by sreelekh N on 10/12/21.
//

import UIKit
extension ActionSheetViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch renderFor {
        case .connectionActionSheet:
            return ActionSheetContent.connections.array.count
        case .thirdPartyPage(sections: let sections), .history(sections: let sections):
            return sections.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: ActionSheetTableViewCell.self, for: indexPath)
        cell.tag = indexPath.row
        switch renderFor {
        case .connectionActionSheet:
            cell.loadData(row: indexPath.row, selectedIndex: selectedIndex)
        case .thirdPartyPage,.history:
            cell.loadData(renderFor: renderFor, row: indexPath.row, selectedIndex: selectedIndex)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {}
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.prepareForReuse()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let holder = selectedIndex
        selectedIndex = indexPath.row
        pageDelegate?.sheetFilterAction(index: indexPath.row)
        tableView.reloadRow(0, holder)
        tableView.reloadRow(0, selectedIndex)
    }
}
