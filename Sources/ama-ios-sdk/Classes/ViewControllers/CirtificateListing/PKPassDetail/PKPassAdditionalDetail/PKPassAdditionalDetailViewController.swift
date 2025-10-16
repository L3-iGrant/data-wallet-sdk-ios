//
//  PKPassAdditionalDetailViewController.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 23/12/21.
//

import UIKit
import WXNavigationBar
final class PKPassAdditionalDetailViewController: AriesBaseViewController, NavigationHandlerProtocol {
    
    override var wx_barTintColor: UIColor? {
        return labelColor ?? .darkGray
    }
    
    override var wx_titleTextAttributes: [NSAttributedString.Key : Any]? {
        return [.foregroundColor: labelColor ?? .darkGray]
    }
    
    func rightTapped(tag: Int) {
        showValues = !showValues
        addNavigationItems()
        tableview.reloadData()
    }
    
    let tableview = UITableView.getTableview()
    var navHandler: NavigationHandler!
    
    override func loadView() {
        super.loadView()
        view.addSubview(tableview)
        tableview.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        tableview.estimatedRowHeight = UITableView.automaticDimension
        tableview.register(cellType: CovidValuesRowTableViewCell.self)
    }
    
    var backFieldArray: [IDCardAttributes] = []
    var showValues = false
    var labelColor: UIColor?
    var bgColor: UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = bgColor ?? .clear
        self.title = "Additional Details".localizedForSDK()
        navHandler = NavigationHandler(parent: self, delegate: self)
        addNavigationItems()
        loadContentSize()
    }
    
    private func loadContentSize() {
        let details = backFieldArray.createAndFindNumberOfLines()
        backFieldArray = details
        self.tableview.delegate = self
        self.tableview.dataSource = self
        
    }
    
    private func addNavigationItems() {
        navHandler.setNavigationComponents(right: [!showValues ? .eye : .eyeFill], tint: labelColor ?? .darkGray)
    }
}

extension PKPassAdditionalDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.backFieldArray.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
        if let data = self.backFieldArray[safe: indexPath.row] {
            cell.setData(model: data, blurStatus: showValues)
            cell.renderUI(index: indexPath.row, tot: self.backFieldArray.count)
        }
        
        if let labelColor = labelColor {
            cell.renderForPKPass(clr: labelColor)
        }
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.zero
    }
}
