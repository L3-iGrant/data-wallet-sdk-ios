//
//  DWGenericViewController + UITableView.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 05/01/23.
//

import Foundation
import UIKit

extension DWGenericViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension DWGenericViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.credentialModel?.attributes?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
