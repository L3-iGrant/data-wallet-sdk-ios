//
//  DWGenericViewController.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 05/01/23.
//

import UIKit

class DWGenericViewController: AriesBaseViewController {

    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var FooterStackView: UIStackView!
    var viewModel = DWGenericViewModel()
    
    class func createNewInstance(mode: DWGenericViewMode?, credentialModel: CustomWalletRecordCertModel?) -> DWGenericViewController {
        let vc = DWGenericViewController(nibName: "DWGenericViewController", bundle: Constants.bundle)
        vc.viewModel.mode = mode ?? .create
        vc.viewModel.credentialModel = credentialModel
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }


}
