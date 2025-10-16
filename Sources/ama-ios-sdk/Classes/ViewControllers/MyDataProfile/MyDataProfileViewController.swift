//
//  MyDataProfileViewController.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 27/11/22.
//

import UIKit

protocol MyDataProfileProtocol {
    func refreshUI()
    func pop()
    func popToRootVC()
}

class MyDataProfileViewController: AriesBaseViewController {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nextButton: UIButton!
    var viewModel = MyDataProfileViewModel.init()
    var navHandler: NavigationHandler!

    override func viewDidLoad() {
        super.viewDidLoad()
        setNav()
        viewModel.pageDelegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: MyDataProfileTableViewCell.self)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        self.name.text = viewModel.getTitle()
        nextButton.layer.cornerRadius = 23
        nextButton.layer.masksToBounds = true
        updateUI()
    }
    
    private func setNav() {
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(title: "MyData Profile".localizedForSDK(),
                                           right: [])
    }
    
    func updateUI(){
        switch viewModel.mode{
        case .view:
            nextButton.isHidden = true
            navHandler.setNavigationComponents(right: [.edit])
        case .create:
            nextButton.isHidden = false
            navHandler.setNavigationComponents(right: [])
        case .edit:
            nextButton.isHidden = false
            navHandler.setNavigationComponents(right: [])
        }
        self.tableView.reloadData()
    }
    
    @IBAction func tappedOnNextButton(_ sender: Any) {
        if viewModel.checkMandatoryFields(){
            viewModel.save()
        } else {
            UIApplicationUtils.showErrorSnackbar(message: "Please fill all manadatory fields")
        }
    }
    
    func updateTitleIfRequired(value: MyDataProfileModel?){
        if value?.label == "First Name" || value?.label == "Last Name"{
            self.name.text = self.viewModel.getTitle()
        }
    }
    
    func deleteAction() {
        AlertHelper.shared.askConfirmationRandomButtons(message: "delete_item_message".localizedForSDK(), btn_title: ["Yes".localizedForSDK(), "No".localizedForSDK()], completion: { [weak self] row in
            switch row {
            case 0:
                self?.viewModel.deleteCard()
            default:
                break
            }
        })
    }
    
}

extension MyDataProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section != 0 {
            return 20
        } else {
            return CGFloat.leastNonzeroMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == (tableView.numberOfSections - 1) {
            return viewModel.mode == .view ? 60 : CGFloat.leastNonzeroMagnitude
        } else {
            return CGFloat.leastNonzeroMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: MyDataProfileTableViewCell.self, for: indexPath)
        let section = indexPath.section
        let row = indexPath.row
        let item = viewModel.items[section][row]
        cell.data = item
        cell.itemName.text = item.label
        cell.itemValue.text = item.value
        cell.itemValue.placeholder = item.label
        if viewModel.mode == .view {
            cell.rightIcon.isHidden = true
            cell.itemValue.isUserInteractionEnabled = false
        } else {
            cell.rightIcon.isHidden = false
            cell.itemValue.isUserInteractionEnabled = true
        }
        cell.renderUI(index: indexPath.row, tot: tableView.numberOfRows(inSection: indexPath.section))
        if item.isMandatory ?? false {
            cell.itemName.addAasterisk()
        }
        cell.onValueChanged = updateTitleIfRequired
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = RemoveBtnVew()
        view.tapAction = { [weak self] in
            self?.deleteAction()
        }
        view.value = "Remove data card".localizedForSDK()
        return view
    }
}

extension MyDataProfileViewController: NavigationHandlerProtocol {
    func rightTapped(tag: Int) {
        viewModel.mode = .edit
        updateUI()
    }
}

extension MyDataProfileViewController: MyDataProfileProtocol {
    func refreshUI() {
        self.updateUI()
    }
    
    func popToRootVC() {
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func pop() {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
