//
//  Untitled.swift
//  Pods
//
//  Created by iGrant on 17/03/25.
//


import UIKit

final class SelfAttestedCertificatePreviewController: AriesBaseViewController {
    
    
    var navHandler: NavigationHandler!
    var showValues = false
    let tableView = UITableView.getTableview()
    let viewModel: SelfAttestedCertificatePreviewViewModel?
    let descriptionLabel = UILabel()
    let overViewLabel = UILabel()

    let readMoreButton = UIButton(type: .system)
    var isExpanded = false
    
    init(vm: SelfAttestedCertificatePreviewViewModel?) {
        viewModel = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("error inside cirtificate invoke")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.viewModel?.certModel?.value?.searchableText
        navHandler = NavigationHandler(parent: self, delegate: self)
        addNavigationItems()
        view.addSubview(tableView)
        
        // Overview
        overViewLabel.font = UIFont.systemFont(ofSize: 17,weight: .regular)
        overViewLabel.text = "Overview".uppercased()
        overViewLabel.isHidden = true
        overViewLabel.sizeToFit()
        view.addSubview(overViewLabel)
        
        //Description
        descriptionLabel.font = UIFont.systemFont(ofSize: 15,weight: .regular)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.text = self.viewModel?.certModel?.value?.headerFields?.desc
        view.addSubview(descriptionLabel)
        
        overViewLabel.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, bottom: descriptionLabel.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingLeft: 20, paddingRight: 20)
        descriptionLabel.addAnchor(top: overViewLabel.bottomAnchor, bottom: tableView.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingLeft: 20, paddingRight: 20)

        tableView.addAnchor(top: descriptionLabel.safeAreaLayoutGuide.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset.top = 20
        viewModel?.pageDelegate = self
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureDescriptionText()
    }
    
    @objc func toggleReadMore() {
        isExpanded.toggle()
        descriptionLabel.numberOfLines = isExpanded ? 0 : 2
        configureDescriptionText()
    }
    
    private func configureDescriptionText() {
        guard let text = self.viewModel?.certModel?.value?.headerFields?.desc else { return }

        let readMoreText = " Read More"
        let readLessText = " Read Less"

        let isShort = isDescriptionShort()
        if !isShort {
            let truncatedText = isShort ? text : "\(text.prefix(80))"
            let displayText = isExpanded ? "\(text)\(readLessText)" : "\(truncatedText)\(readMoreText)"
            
            let attributeString = NSMutableAttributedString(string: displayText)
            
            if !isExpanded {
                attributeString.addAttribute(.foregroundColor,
                                             value: UIColor(red: 0.59, green: 0.59, blue: 0.61, alpha: 1),
                                             range: NSRange(location: truncatedText.count, length: readMoreText.count))
            }
            
            if isExpanded {
                attributeString.addAttribute(.foregroundColor,
                                             value: UIColor(red: 1, green: 0.53, blue: 0.54, alpha: 1),
                                             range: NSRange(location: text.count, length: readLessText.count))
            }
            
            descriptionLabel.attributedText = attributeString
            descriptionLabel.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleReadMore))
            descriptionLabel.addGestureRecognizer(tapGesture)
        } else {
            descriptionLabel.text = text
        }
    }
    
    private func isDescriptionShort() -> Bool {
        descriptionLabel.layoutIfNeeded()
        guard let text = self.viewModel?.certModel?.value?.headerFields?.desc else { return true }
        
        let maxHeight = descriptionLabel.font.lineHeight * 2
        let boundingBox = (text as NSString).boundingRect(
            with: CGSize(width: descriptionLabel.frame.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: descriptionLabel.font],
            context: nil
        )
        
        return boundingBox.height <= maxHeight
    }
    
    func addNavigationItems() {
        navHandler.setNavigationComponents(right: [!showValues ? .eye : .eyeFill])
    }
    
    func deleteAction() {
        AlertHelper.shared.askConfirmationRandomButtons(message: "delete_item_message".localizedForSDK(), btn_title: ["Yes".localizedForSDK(), "No".localizedForSDK()], completion: { [weak self] row in
            switch row {
            case 0:
                self?.deleteCard()
            default:
                break
            }
        })
    }
    
    private func deleteCard() {
        print("ghgggg: \(self.viewModel?.certModel?.id )")
        self.viewModel?.deleteCredentialWith(id: self.viewModel?.certModel?.value?.referent?.referent ?? "", walletRecordId: self.viewModel?.certModel?.id ?? "")
    }
    
}

extension SelfAttestedCertificatePreviewController: NavigationHandlerProtocol {
    
    func rightTapped(tag: Int) {
        showValues = !showValues
        addNavigationItems()
        self.tableView.reloadInMain()
    }
}

extension SelfAttestedCertificatePreviewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel?.certModel?.value?.attributes?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var attrArray: [IDCardAttributes] = []
        let grouped = self.viewModel?.certModel?.value?.attributes?.orderedValues
        grouped?.forEach { e in
            attrArray.append(IDCardAttributes(name: e.label, value: e.value))
        }
        let renderedAttribues = attrArray.createAndFindNumberOfLines()
        guard let data = renderedAttribues[safe: indexPath.row] else { return UITableViewCell()}
        let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
            cell.setData(model: data, blurStatus: showValues)
            cell.renderUI(index: indexPath.row, tot: renderedAttribues.count )
        cell.arrangeStackForDataAgreement()
        cell.layoutIfNeeded()
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
}

extension SelfAttestedCertificatePreviewController: CirtificateDelegate {
    
    func idCardSaved() {}
    
    func updateUI() {}
    
    func popVC() {
        self.pop()
    }
    
    func notSupportedPKPass() {}
    
}
