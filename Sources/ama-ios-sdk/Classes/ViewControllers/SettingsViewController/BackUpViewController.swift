//
//  BackUpViewController.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 24/03/23.
//

import UIKit
import RadioGroup
import UniformTypeIdentifiers

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

class BackUpViewController: UIViewController, UITextFieldDelegate, NavigationHandlerProtocol {
    func leftTapped(tag: Int) {
        self.returnBack()
    }
    
    func rightTapped(tag: Int) {
        
    }
    
    let mainRadioGroup = RadioGroup(titles: ["backup_and_restore_disable_backup".localize, "backup_and_restore_enable_backup".localize])
   // let disabledRadioGroup = RadioGroup(titles: [ "backup_and_restore_solid_pods".localize])
    let lastBackUpText = UILabel()
    var navHandler: NavigationHandler!
    let dataPodUserNameTextField = UITextField()
    let dataPodsLabel = UILabel()
    let dataPodUrlLabel = UILabel()
    let backUpButton: UIButton = {
        let backUpButton = UIButton()
        backUpButton.setTitle("backup_and_restore_backup_now".localize, for: .normal)
        backUpButton.backgroundColor = .black
        backUpButton.setTitleColor(.white, for: .normal)
        backUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        backUpButton.maskedCornerRadius = 23
        return backUpButton
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Storage and Backup"
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = .left
        return label
    }()

    private let closeButton: UIButton = {
        let config = UIImage.SymbolConfiguration(scale: .small)
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 12.5
        button.backgroundColor = UIColor(hex: "d1d2d9")
        button.tintColor = .black
        return button
    }()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardToolbar()
        updateLeftBarButtonForSDK()
        getLatestBackupFileFromDatapods()
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            setupBottomSheetHeader()
        } else {
            updateLeftBarButtonForSDK()
        }
        view.backgroundColor = UIColor.appColor(.walletBg)
        self.title = "backup_and_restore_storage_and_backup".localizedForSDK()
        navigationItem.leftBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)

        let subTitle = UILabel()
        subTitle.font = UIFont.systemFont(ofSize: 15,weight: .regular)
        subTitle.numberOfLines = 0
        view.addSubview(subTitle)
        
        // User name textfield
        dataPodUserNameTextField.font = .systemFont(ofSize: 12)
        dataPodUserNameTextField.delegate = self
        dataPodUserNameTextField.borderStyle = .roundedRect
        dataPodUserNameTextField.setLeftPaddingPoints(5)
        dataPodUserNameTextField.placeholder = "Username".localized()
        dataPodUserNameTextField.isUserInteractionEnabled = true
        dataPodUserNameTextField.autocapitalizationType = .none
        dataPodUserNameTextField.keyboardType = .alphabet
        
        // data pod label
        dataPodsLabel.text = "Data pods by iGrant.io".localized().uppercased()
        dataPodsLabel.font = .systemFont(ofSize: 15)
        dataPodsLabel.textColor = .darkGray
        
        // data pod url label
        dataPodUrlLabel.text = "https://.datapod.igrant.io"
        dataPodUrlLabel.font = .systemFont(ofSize: 12)
        dataPodUrlLabel.textColor = .darkGray

        view.addSubview(dataPodsLabel)
        view.addSubview(dataPodUserNameTextField)
        view.addSubview(dataPodUrlLabel)
        view.addSubview(backUpButton)
        showDataPodElements()
        
        backUpButton.addTarget(self, action: #selector(tappedOnBackUp), for: .touchUpInside)
        
        //subTitle.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingLeft: 25, paddingRight: 25, height: 0)
        let topAnchorRef = (AriesMobileAgent.shared.getViewMode() == .BottomSheet) ? titleLabel.bottomAnchor : view.safeAreaLayoutGuide.topAnchor
        subTitle.addAnchor(top: topAnchorRef, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingRight: 20, height: 0)

        backUpButton.addAnchor( bottom: view.bottomAnchor,paddingBottom: 45, width: 180, height: 45,centerX: view.centerXAnchor)
        
        lastBackUpText.font = UIFont.systemFont(ofSize: 13,weight: .regular)
        lastBackUpText.numberOfLines = 0
        lastBackUpText.textAlignment = .left
        lastBackUpText.textColor = .lightGray
        view.addSubview(lastBackUpText)
        lastBackUpText.text = ""
        
        dataPodsLabel.addAnchor(top: subTitle.bottomAnchor , left: subTitle.leftAnchor, right: subTitle.rightAnchor, paddingTop: 15, paddingBottom: 10, paddingRight: 10)
        dataPodUserNameTextField.addAnchor(top: dataPodsLabel.bottomAnchor , left: dataPodsLabel.leftAnchor, right: dataPodsLabel.rightAnchor, paddingTop: 10, paddingBottom:  10)
        dataPodUrlLabel.addAnchor(top: dataPodUserNameTextField.bottomAnchor , left: dataPodUserNameTextField.leftAnchor, right: dataPodUserNameTextField.rightAnchor, paddingTop: 5)
        lastBackUpText.addAnchor(top: dataPodUrlLabel.bottomAnchor, left: dataPodUrlLabel.leftAnchor, right: dataPodUrlLabel.rightAnchor,paddingTop: 20)
            
        if let podName = UserDefaults.standard.string(forKey: "podName") {
            dataPodUserNameTextField.text = podName
            dataPodUrlLabel.text = "https://\(podName).datapod.igrant.io"
        }
    }
    
    func updateLeftBarButtonForSDK(){
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(left: [.back])
    }
    
    private func setupBottomSheetHeader() {
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25),
            
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    @objc private func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setupKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexibleSpace, doneButton]
        dataPodUserNameTextField.inputAccessoryView = toolbar
    }
    
    @objc func tappedOnBackUp(){
        exportToDataPods()
    }
    
    func getLatestBackUpFileForiCloud(){
        guard let containerUrl = Constants.iCloudBackupURL, let urlArray = try? FileManager.default.contentsOfDirectory(
            at: containerUrl,
            includingPropertiesForKeys: [.contentModificationDateKey]),
              urlArray.isNotEmpty else {
            return
        }
        
        let sorted = urlArray.map { url in
            (url.lastPathComponent, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
        }.sorted(by: { $0.1 > $1.1 }) // sort descending modification dates
            .map { $0.1 } // extract date
        if let date = sorted.first {
            let backupFile = formatDate(date: date, format: "dd-MM-yyyy hh:mm a")
            lastBackUpText.text = "backup_and_restore_last_backup".localizedForSDK() + ": " + backupFile
        } else {
            lastBackUpText.text = ""
        }
        
    }
    
    func getLatestBackupFileFromDatapods(){
        DataPodsUtils.shared.getLatestBackupFileDate {[weak self] dateString in
            guard let strongSelf = self else {return}
            var formattedDate = ""
            if let dateString = dateString,
               let timeInterval = Double(dateString) {
                let date = Date(timeIntervalSince1970: timeInterval)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd hh:mm:ss a"
                formatter.amSymbol = "AM"
                formatter.pmSymbol = "PM"
                formattedDate = formatter.string(from: date)
            }
            DispatchQueue.main.async {
                strongSelf.lastBackUpText.text = "backup_and_restore_last_backup".localize + ": " + (formattedDate ?? "")
            }
        }
    }
    
    func formatDate(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    func addDivider(view: UIView){
        for i in [40,80]{
            let divider = UIView()
            divider.backgroundColor =  UIColor.appColor(.walletBg)
            view.addSubview(divider)
            divider.addAnchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor,paddingTop: CGFloat(i), height: 2)
        }
    }
    
    func tappedOnExport() {
        exportToDataPods() //datapods
    }
    
    func exportToCustom(){
        var documentPicker: UIDocumentPickerViewController!
        if #available(iOS 14, *) {
            // iOS 14 & later
            let supportedTypes: [UTType] = [UTType.folder]
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        } else {
            // iOS 13 or older code
            let supportedTypes: [String] = ["UTTypeFolder"]
            documentPicker = UIDocumentPickerViewController(documentTypes: supportedTypes, in: .import)
        }
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        documentPicker.view.tag = 0
        
        present(documentPicker, animated: true, completion: nil)
    }
    
    func exportToiCloud(){
        ExportImportWallet.shared.exportWallet(type: .iCloud) {[weak self] success in
            guard let strongSelf = self else {return}
            if success {
                strongSelf.getLatestBackUpFileForiCloud()
            }
        }
    }
    
    func exportToDataPods(){
        if dataPodUserNameTextField.text == "" {
            UIApplicationUtils.showErrorSnackbar(message: "Please enter username".localized())
            return
        }
        DataPodsUtils.shared.userProvidedURL = dataPodUrlLabel.text ?? ""
        
        ExportImportWallet.shared.exportWallet(type: .dataPods) {[weak self] success in
            guard let strongSelf = self else {return}
            if success {
                strongSelf.getLatestBackupFileFromDatapods()
                DispatchQueue.main.async {
                    UIApplicationUtils.showSuccessSnackbar(message: "Backup successfully!")
                    UserDefaults.standard.set(self?.dataPodUserNameTextField.text ?? "", forKey: "podName")
                }
            }
        }
    }
    
    func tappedOnImport() {
        var documentPicker: UIDocumentPickerViewController!
        if #available(iOS 14, *) {
            // iOS 14 & later
            let supportedTypes: [UTType] = [UTType.data, .item]
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        } else {
            // iOS 13 or older code
            let supportedTypes: [String] = ["UTTypeScript"]
            documentPicker = UIDocumentPickerViewController(documentTypes: supportedTypes, in: .import)
        }
        documentPicker.delegate = self
        documentPicker.view.tag = 1
        documentPicker.modalPresentationStyle = .formSheet
        documentPicker.directoryURL = Constants.iCloudBackupURL
        present(documentPicker, animated: true, completion: nil)
    }
    
    func hideDataPodElements() {
        dataPodsLabel.isHidden = true
        dataPodUserNameTextField.isHidden = true
        dataPodUrlLabel.isHidden = true
    }
   
    func showDataPodElements() {
        dataPodsLabel.isHidden = false
        dataPodUserNameTextField.isHidden = false
        dataPodUrlLabel.isHidden = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.letters
        let allowedNumbers = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        if !allowedCharacters.isSuperset(of: characterSet) && !allowedNumbers.isSuperset(of: characterSet) {
            return false
        }
        guard let currentText = textField.text else {
            return true
        }
        let containsSpace = string.rangeOfCharacter(from: .whitespaces) != nil
        if containsSpace {
            return false
        }
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)

        dataPodUrlLabel.text = "https://\(newText).datapod.igrant.io"
        return true
    }
}

extension BackUpViewController: UIDocumentMenuDelegate,UIDocumentPickerDelegate,UINavigationControllerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let myURL = urls.first else {
            return
        }
        ExportImportWallet.shared.exportWallet(path: myURL.path)
    }
    
    public func documentMenu(_ documentMenu:UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
}

