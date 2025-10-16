//
//  MyDataProfileViewModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 27/11/22.
//

import Foundation

enum BasicUIModes {
    case create
    case view
    case edit
}

struct MyDataProfileViewModel {
    
    var items: [[MyDataProfileModel]] = [[]]
    var mode: BasicUIModes = .create
    var pageDelegate: MyDataProfileProtocol?

    var walletModel: SearchItems_CustomWalletRecordCertModel? {
        didSet {
            populateItems()
            mode = .view
        }
    }

    init() {
        items = MyDataProfileDataManager().getMetaModel()?.first?.convertToMyDataProfileMetaDataModel() ?? []
        debugPrint(items)
    }
    
    func populateItems(){
        items.forEach { subItems in
            subItems.forEach { e in
                e.value = walletModel?.value?.attributes?[e.key ?? ""]?.value ?? ""
            }
        }
    }
    
    func deleteCard(){
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: walletModel?.id ?? "") { (success, error) in
            NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
            self.pageDelegate?.pop()
        }
    }
    
    func getTitle() -> String {
        (items.first?.first?.value ?? "") + " " + ((items.first?[1].value ?? ""))
    }
    
    func save() {
        Task {
            //convert the mydataprofilemodel to generic data wallet model
            var dw_attributeModel: OrderedDictionary<String,DWAttributesModel> = [:]
            var sectionStruct: [DWSection] = []
            for (index,item) in items.enumerated() {
                item.forEach{ e in
                    dw_attributeModel[(e.key ?? "")] = e.convertToDWAttributeModel(parent: "section\(index)")
                }
                sectionStruct.append(DWSection(title: "", key: "section\(index)"))
            }
            let customWalletModel = CustomWalletRecordCertModel.init()
            customWalletModel.attributes = dw_attributeModel
            customWalletModel.type = CertType.selfAttestedRecords.rawValue
            customWalletModel.subType = SelfAttestedCertTypes.profile.rawValue
            customWalletModel.searchableText = "MyData Profile"
            customWalletModel.sectionStruct = sectionStruct
            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
            
            do {
                if mode == .create {
                    let (success,_) =  try await WalletRecord.shared.add(connectionRecordId: "",walletCert: customWalletModel, walletHandler: walletHandler, type: .walletCert)
                    if success {
                        NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                        self.pageDelegate?.popToRootVC()
                    }
                } else {
                    let success =  try await WalletRecord.shared.update(walletHandler: walletHandler, recordId: walletModel?.id ?? "", type: AriesAgentFunctions.walletCertificates, value: UIApplicationUtils.shared.getJsonString(for: customWalletModel.dictionary ?? [:]) )
                    if success {
                        NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                        self.pageDelegate?.popToRootVC()
                    }
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    func checkMandatoryFields() -> Bool{
        if items.first(where: { subItems in
            subItems.first { e in
                (e.isMandatory ?? false) && ((e.value ?? "").isEmpty)
            } != nil
        }) != nil {
            return false
        } else {
            return true
        }
    }
}
