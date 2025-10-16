//
//  MetaDataUtils.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 02/02/22.
//

import Foundation

final class MetaDataUtils {
    static let shared = MetaDataUtils()
    
    let coreDataManager: CoreDataManager
    
    init() {
        coreDataManager = CoreDataManager()
    }
    
    func checkForMetaDataUpdate() {
        NetworkManager.shared.get(service: .getDataWalletMetaData) { [weak self] jsonData in
            if let data = jsonData, let dataWalletMetadata = try? JSONDecoder().decode(MetaDataModel.self, from: data) {
                if let localData = self?.coreDataManager.getlastUpdatedMetaData() {
                    if localData != dataWalletMetadata {
                        self?.coreDataManager.addDataWalletLastUpdate(data: dataWalletMetadata) { [weak self] in
                            self?.compareAndUpdateLocalData(server_lastUpdated: dataWalletMetadata, local_lastUpdated: localData)
                        }
                    } else {
                        debugPrint("Metadata sync: Nothing to update")
                    }
                } else {
                    self?.coreDataManager.addDataWalletLastUpdate(data: dataWalletMetadata) { [weak self] in
                        self?.updateAllMetaData()
                    }
                }
            }
        }
    }
    
    private func compareAndUpdateLocalData(server_lastUpdated: MetaDataModel, local_lastUpdated: MetaDataModel){
        if local_lastUpdated.ledgerNetwork != server_lastUpdated.ledgerNetwork {
            updateGenesis()
        }
        if local_lastUpdated.pkpassBoardingPass != server_lastUpdated.pkpassBoardingPass {
            updatePKPassMetaData { }
        }
        if local_lastUpdated.blinks != server_lastUpdated.blinks {
            updateBlinks()
        }
        if local_lastUpdated.myDataProfile != server_lastUpdated.myDataProfile {
            updateMyDataProfile()
        }
    }
    
    private func updateAllMetaData(){
        updateGenesis()
        updatePKPassMetaData{}
        updateBlinks()
        updateMyDataProfile()
    }
    
    func updatePKPassMetaData(completion: @escaping (()->Void)){
        NetworkManager.shared.get(service: .getPKPassBoardingMetaData) { jsonData in
            guard let data = jsonData else { return }
            self.coreDataManager.addPKPassBoardingPassMetadata(data: data) {
                debugPrint("PKPass synced")
                completion()
            }
        }
    }
    
    private func updateGenesis() {
        NetworkManager.shared.get(service: .getGenesis) { jsonData in
            guard let data = jsonData else {
                return
            }
            if let genesisListModel = try? JSONDecoder().decode([GenesisModel].self, from: data) {
                self.coreDataManager.addGenesis(model: genesisListModel) {
                    debugPrint("Ledger synced")
                }
            }
        }
    }
    
    private func updateBlinks() {
        NetworkManager.shared.get(service: .getBlinksMetaData) { jsonData in
            guard let data = jsonData else {
                return
            }
            if let blinksListModel = try? JSONDecoder().decode([BlinksModel].self, from: data) {
                self.coreDataManager.addBlinks(model: blinksListModel) {
                    debugPrint("Blinks synced")
                }
            }
        }
    }
    
    private func updateMyDataProfile() {
        NetworkManager.shared.get(service: .getMyDataProfileMetaData) { jsonData in
            guard let data = jsonData else {
                return
            }
            if let _ = try? JSONDecoder().decode([[MyDataProfileModel]].self, from: data) {
                self.coreDataManager.addMyDataProfile(model: MyDataProfileMetaDataModel.init(data: data)) {
                    debugPrint("MyDataProfile synced")
                }
            }
        }
    }
    
    func getBlinkFromPrefix(prefix: String) -> BlinksModel?{
        return coreDataManager.getBlinksFromPrefix(prefix: prefix)
    }
}


//   let dataWalletMetadata = try? newJSONDecoder().decode(DataWalletMetadata.self, from: jsonData)

//struct DataWalletMetadata: Codable,Equatable {
//    let ledgerNetwork, pkpassBoardingPass: String
//    
//    enum CodingKeys: String, CodingKey {
//        case ledgerNetwork = "ledger_network"
//        case pkpassBoardingPass = "pkpass_boarding_pass"
//    }
//    
//    func isEqualTo(_ object: Any) -> Bool {
//        guard let otherObj = object as? DataWalletMetadata else { return false }
//        
//        return ledgerNetwork == otherObj.ledgerNetwork && pkpassBoardingPass == otherObj.pkpassBoardingPass
//    }
//}
