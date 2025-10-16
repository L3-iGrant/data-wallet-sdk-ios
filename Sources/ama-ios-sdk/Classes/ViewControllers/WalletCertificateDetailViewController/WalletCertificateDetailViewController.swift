//
//  WalletCertificateDetailViewController.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 22/01/21.
//

import UIKit

class WalletCertificateDetailViewController: AriesBaseViewController,UITableViewDelegate, UITableViewDataSource,WalletCertificateDetailDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var viewModel: WalletCertificateDetailViewModel?
    @IBOutlet weak var navTitleLbl: UILabel!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var moreBtn: UIButton!
    @IBOutlet var topConstraint : NSLayoutConstraint!
    @IBOutlet var topBarItemConstraint : NSLayoutConstraint!
    var showValues = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        viewModel?.getOrgInfo(completion: {[weak self] (success) in
            self?.tableView.reloadData()
        })
        viewModel?.delegate = self
        setupUI()
        moreBtn.tintColor = .white
        moreBtn.isHidden = false
        moreBtn.setImage("eye".getImage(), for: .normal)
        moreBtn.addTarget(self, action:  #selector(tappedOnEyeButton), for: .touchUpInside)
    }
    
    @objc func tappedOnEyeButton(){
        showValues = !showValues
        moreBtn.setImage(!showValues ? "eye".getImage() :  "eye.slash".getImage(), for: .normal)
        self.tableView.reloadData()
    }
    
    func setupUI() {
        if UIDevice.current.hasNotch {
            topConstraint.constant = -45.0
            topBarItemConstraint.constant = -15.0
        }
        tableView.estimatedRowHeight = 40
        self.tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        backBtn.layer.cornerRadius =  backBtn.frame.size.height/2
        moreBtn.layer.cornerRadius =  moreBtn.frame.size.height/2
    }
    
    override func localizableValues() {
        super.localizableValues()
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.contentInset.top = -10
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        UIView.animate(withDuration: 0) {
            self.wx_navigationBar.isHidden = true
            self.navigationController?.navigationBar.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.reloadData()
    }
    
    func popVC() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func backButtonClicked(){
        self.navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let orgCell = tableView.dequeueReusableCell(withIdentifier:"WalletDetailTopSectionTableViewCell",for: indexPath) as! WalletDetailTopSectionTableViewCell
            orgCell.nameLbl.text = viewModel?.orgInfo?.name ?? (viewModel?.certModel?.value?.connectionInfo?.value?.theirLabel ?? "")
            orgCell.locationLbl.text = viewModel?.orgInfo?.location ?? ""
            UIApplicationUtils.shared.setRemoteImageOn(orgCell.logoImageView, url: viewModel?.orgInfo?.logoImageURL ?? (viewModel?.certModel?.value?.connectionInfo?.value?.imageURL ?? ""))
            UIApplicationUtils.shared.setRemoteImageOn(orgCell.orgImageView, url: viewModel?.orgInfo?.coverImageURL ?? (viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.coverImageURL ?? ""),placeholderImage: "00_Default_CoverImage_02-min".getImage())
            orgCell.selectionStyle = .none
            return orgCell
        
        case (tableView.numberOfRows(inSection: 0) - 1):
            let cell:WalletDetailDeleteTableViewCell? = tableView.dequeueReusableCell(withIdentifier: "WalletDetailDeleteTableViewCell") as? WalletDetailDeleteTableViewCell
            cell?.selectionStyle = .none
            cell?.name.text = "Remove data card".localizedForSDK()
            if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
                cell?.separatorInset = UIEdgeInsets(top: 0, left: cell?.bounds.size.width ?? 0, bottom: 0, right: 0)
            }else{
                cell?.separatorInset = UIEdgeInsets.zero
            }
            return cell ?? UITableViewCell()
            
        default:
            let cell:CertificateWithDataTableViewCell? = tableView.dequeueReusableCell(withIdentifier: "CertificateWithDataTableViewCell") as? CertificateWithDataTableViewCell
            var attrArray:[IDCardAttributes] = []
            var certName = ""
            if let EBSI_attr = viewModel?.certModel?.value?.EBSI_v2 {
                attrArray = EBSIWallet.shared.getEBSI_V2_attributes(section: indexPath.row - 1, certModel: viewModel?.certModel)
                if viewModel?.isEBSI_diploma() ?? false{
                    switch (indexPath.row - 1){
                    case 0: certName = "Identifier".uppercased()
                    case 1: certName = "Specified by".uppercased()
                    case 2: certName = "was awarded by".uppercased()
                    default: certName = "Identifier".uppercased()
                    }
                } else {
                    certName = viewModel?.certModel?.value?.searchableText ?? ""
                }
            } else {
                attrArray = viewModel?.certDetail?.value?.credentialProposalDict?.credentialProposal?.attributes?.map({ (item) -> IDCardAttributes in
                    return IDCardAttributes.init(type: CertAttributesTypes.string, name: item.name, value: item.value)
                }) ?? []
                let schemeSeperated = viewModel?.certDetail?.value?.schemaID?.split(separator: ":")
                certName = "\(schemeSeperated?[2] ?? "")".uppercased()
            }
            cell?.certData = attrArray
            cell?.blurValues = !showValues
            cell?.certName.text = certName
            cell?.selectionStyle = .none
            return cell ?? UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel?.isEBSI_diploma() ?? false {
            return 5
        }
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch  indexPath.row {
        case 0:
            return 245
        case (tableView.numberOfRows(inSection: 0) - 1):
            return 70
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == (tableView.numberOfRows(inSection: 0) - 1) { //delete
            let alert = UIAlertController(title: "Data Wallet", message: "delete_item_message".localizedForSDK(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes".localizedForSDK(), style: .default, handler: { [self] action in
                self.viewModel?.deleteCredentialWith(id: self.viewModel?.certModel?.value?.referent?.referent ?? "", walletRecordId: viewModel?.certModel?.id)
                alert.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "No".localizedForSDK(), style: .default, handler: { action in
                alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
