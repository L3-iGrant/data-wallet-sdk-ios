//
//  RestoreDataPodViewController.swift
//  ama-ios-sdk
//
//  Created by iGrant on 24/04/25.
//

import UIKit

class RestoreDataPodViewController: UIViewController, UITextFieldDelegate, NavigationHandlerProtocol {
    
    func leftTapped(tag: Int) {
        self.returnBack()
    }
    
    func rightTapped(tag: Int) {
        
    }
    
    var navHandler: NavigationHandler!
    let urlPreviewLabel = UILabel()
    let userTextField = UITextField()
    var backupFileUrl: URL? = nil
    var onRestoreCompleted: ((Bool) -> Void)?
    let nextButton: UIButton = {
        let nextButton = UIButton()
        nextButton.setTitle("Next".localize, for: .normal)
        nextButton.backgroundColor = .black
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        nextButton.addTarget(self, action: #selector(RestoreToDatapods), for: .touchUpInside)
        nextButton.maskedCornerRadius = 23
        return nextButton
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
    
    override func loadView() {
        super.loadView()
        view.addSubview(nextButton)
        nextButton.addAnchor(bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingLeft: 55, paddingBottom: 45, paddingRight: 55, height: 50)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            setupBottomSheetHeader()
        } else {
            updateLeftBarButtonForSDK()
        }
        view.backgroundColor = UIColor.appColor(.walletBg)
        self.navigationController?.navigationBar.isHidden = false
        setupKeyboardToolbar()
        let title = UILabel()
        title.text = "backup_and_restore_select_backup".localize
        title.textColor = .black
        title.font = UIFont.systemFont(ofSize: 25,weight: .bold)
        view.addSubview(title)
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            title.addAnchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor,paddingTop: topFullArea, paddingLeft: 25, paddingRight: 25)
        } else {
            title.addAnchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor,paddingTop: topFullArea + 50, paddingLeft: 25, paddingRight: 25)
        }
        
        //Subtitle
        let subTitle = UILabel()
        subTitle.text = "backup_and_restore_data_pods_by_igrant".localize.uppercased()
        subTitle.font = UIFont.systemFont(ofSize: 18,weight: .medium)
        subTitle.textColor = .gray
        view.addSubview(subTitle)
        subTitle.addAnchor(top: title.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor,paddingTop: 20, paddingLeft: 25, paddingRight: 20)
        
        //TextField
        userTextField.attributedPlaceholder = NSAttributedString(
            string: "Username".localize,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
        userTextField.textColor = .lightGray
        userTextField.font = UIFont.systemFont(ofSize: 14,weight: .regular)
        userTextField.delegate = self
        userTextField.backgroundColor = .white
        userTextField.maskedCornerRadius = 5
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: userTextField.frame.height))
        userTextField.leftView = paddingView
        userTextField.leftViewMode = .always
        view.addSubview(userTextField)
        userTextField.autocapitalizationType = .none
        userTextField.addAnchor(top: subTitle.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor,paddingTop: 15, paddingLeft: 25, paddingRight: 20, height: 40)
                
        //url preview
        urlPreviewLabel.font = UIFont.systemFont(ofSize: 14,weight: .regular)
        urlPreviewLabel.text = "https://.datapod.igrant.io"
        urlPreviewLabel.textColor = .black
        view.addSubview(urlPreviewLabel)
        urlPreviewLabel.addAnchor(top: userTextField.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor,paddingTop: 10, paddingLeft: 25, paddingRight: 20)
    }
    func updateLeftBarButtonForSDK(){
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(left: [.back])
    }
    
    @objc func RestoreToDatapods() {
        if let podName = urlPreviewLabel.text, !podName.isEmpty {
            DataPodsUtils.shared.userProvidedURL = podName.lowercased()
            ImportPathFromDataPods()
        }
    }
    
    private func setupBottomSheetHeader() {
        view.addSubview(closeButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25)
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
        userTextField.inputAccessoryView = toolbar
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentText = textField.text else {
            return true
        }
        let containsSpace = string.rangeOfCharacter(from: .whitespaces) != nil
        if containsSpace {
            return false
        }
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)

        urlPreviewLabel.text = "https://\(newText).datapod.igrant.io"
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        debugPrint("#In viewWillDisappear:\(userTextField.text ?? "")")
        UserDefaults.standard.set(userTextField.text, forKey: "podName")
    }
    
    func ImportPathFromDataPods(){
        UIApplicationUtils.showLoader()
        DataPodsUtils.shared.getAccessForUser(url: DataPodsUtils.shared.userProvidedURL) { accessToken, isDismissed  in
           if accessToken.isEmpty {
                UIApplicationUtils.hideLoader()
            }
            
            DataPodsUtils.shared.getLatestBackupFileDate { dateString in
                debugPrint("Latest date:\(dateString ?? "")")
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"  // This is the key format
                guard let date = dateFormatter.date(from: dateString ?? "") else {
                    return
                }
//                let finalFileName = dateString + ".db"
//                debugPrint("filename neenu: \(finalFileName)")
                
                let newDateFormatter = DateFormatter()
                newDateFormatter.dateFormat = "dd-MM-yyyy-hhmmss"
                let formattedDateString = newDateFormatter.string(from: date)
                
                let finalFileName = formattedDateString + ".db"
                debugPrint(finalFileName)
                
                DataPodsUtils.shared.downloadFile(fileName: finalFileName) { [weak self] result in
                    UIApplicationUtils.hideLoader()
                    guard let strongSelf = self else {return}
                    
                    switch result {
                    case .success(let filePath):
                        debugPrint("File downloaded successfully. File path: \(filePath)")
                        if let path = URL(string: filePath){
                            strongSelf.backupFileUrl = path
                            if let url = strongSelf.backupFileUrl {
                                UIApplicationUtils.showLoader(message: "Importing...".localized())
                                    ExportImportWallet.shared.importWallet(path: url.path) { [weak self] success in
                                        guard let strongSelf = self else {return}
                                        if success {
                            
                                            strongSelf.backupFileUrl = nil
                                            DispatchQueue.main.async {
                                                UIApplicationUtils.hideLoader()
                                                strongSelf.onRestoreCompleted?(success)
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                UIApplicationUtils.hideLoader()
                                                strongSelf.onRestoreCompleted?(success)
                                            }
                                        }
                                    }
                            }
                        } else {
                            UIApplicationUtils.showErrorSnackbar(message: "Failed to get backup files from Datapods")
                        }
                    case .failure(let error):
                        debugPrint(error.localizedDescription)
                        UIApplicationUtils.hideLoader()
                        UIApplicationUtils.showErrorSnackbar(message: "Failed to get backup files from Datapods")
                    }
                    DispatchQueue.main.async {
                        strongSelf.dismiss(animated: true) {
                        }
                    }
                }
            }
        }
    }
    
}
