//
//  AgentPoolHelper.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 28/11/20.
//

import Foundation
import SVProgressHUD
import ASN1Decoder
import IndyCWrapper

//import LibIndy
//import IndyWrapper

final class AriesPoolHelper {
    static let shared = AriesPoolHelper()
    static var poolHandler = IndyHandle()
    
    let coreDataManager: CoreDataManager
    
    init() {
        coreDataManager = CoreDataManager()
    }
    
    @available(*, renamed: "configurePool(walletHandler:)")
    func configurePool(walletHandler: IndyHandle,completion: @escaping (Bool?) -> Void) {
        self.pool_prover_create_master_secret(walletHandle: walletHandler) {[weak self] (success, masterSecretHandler, error) in
            self?.fetchAndSaveGenesis { [weak self](genesisFilePath) in
                debugPrint("fetch genesis")
                self?.closePoolLedger(poolHandler: AriesPoolHelper.poolHandler) {[weak self] (success, error) in
                    debugPrint("close pool ledger \(success)")
                    self?.deleteDefaultPool { (success, error) in
                        debugPrint("delete default pool ledger \(success)")
                        self?.createDefaultPool(genesisPath: genesisFilePath) {[weak self] (success, error) in
                            debugPrint("create default pool ledger \(success)")
                            if success {
                                self?.pool_setProtocol(version: 2) {[weak self] (success, error) in
                                    debugPrint("set protocol \(success)")
                                    if success {
                                        self?.pool_openLedger(name: "default", config: [String:Any]()) { (success, poolLedgerHandler, error) in
                                            debugPrint("open default pool ledger \(success)")
                                            if success {
                                                AriesPoolHelper.poolHandler = poolLedgerHandler
                                                completion(true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func configurePool(walletHandler: IndyHandle) async -> Bool? {
        return await withCheckedContinuation { continuation in
            configurePool(walletHandler: walletHandler) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    
    @available(*, renamed: "pool_setProtocol(version:)")
    func pool_setProtocol(version: NSNumber,completion: @escaping (Bool,Error?) -> Void){
        AgentWrapper.shared.pool_setProtocol(protocolVersion: version) { (error) in
            if(error?._code == 0){
                debugPrint("pool set protocol")
                completion(true,error)
            } else {
                completion(false,error)
            }
            
        }
    }
    
    func pool_setProtocol(version: NSNumber) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            pool_setProtocol(version: version) { result, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    
    @available(*, renamed: "pool_openLedger(name:config:)")
    func pool_openLedger(name: String,config: [String:Any], completion: @escaping(Bool,IndyHandle,Error?) -> Void){
        AgentWrapper.shared.pool_openPool(withName: name, poolConfig: UIApplicationUtils.shared.getJsonString(for:config)) { (error, poolHandler) in
            if(error?._code == 0){
                debugPrint("pool set protocol")
                completion(true,poolHandler,error)
            } else {
                completion(false,poolHandler,error)
            }
        }
    }
    
    func pool_openLedger(name: String,config: [String:Any]) async throws -> (Bool, IndyHandle) {
        return try await withCheckedThrowingContinuation { continuation in
            pool_openLedger(name: name, config: config) { result1, result2, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    func pool_prover_create_master_secret(walletHandle: IndyHandle,completion: @escaping(Bool,String,Error?) -> Void){
        let deviceID = UIDevice.current.identifierForVendor!.uuidString
        let masterSecretID = "iGrantMobileAgent-\(deviceID)"
        AgentWrapper.shared.pool_prover_create_master_secret(masterSecretID: masterSecretID, walletHandle: walletHandle) { (error, response) in
            if(error?._code == 0){
                debugPrint("pool set protocol")
                completion(true,response ?? "",error)
            } else {
                completion(false,response ?? "",error)
            }
        }
    }
    
    @available(*, renamed: "pool_prover_create_credential_request(walletHandle:forCredentialOffer:credentialDefJSON:proverDID:)")
    func pool_prover_create_credential_request(walletHandle: IndyHandle, forCredentialOffer: String, credentialDefJSON: String, proverDID: String,completion: @escaping(Bool,String,String,Error?) -> Void){
        let deviceID = UIDevice.current.identifierForVendor!.uuidString
        let masterSecretID = "iGrantMobileAgent-\(deviceID)"
        AgentWrapper.shared.pool_prover_create_credential_request(forCredentialOffer: forCredentialOffer, credentialDefJSON: credentialDefJSON, proverDID: proverDID, masterSecretID: masterSecretID, walletHandle: walletHandle) { (error, credReqJSON, credReqMetadataJSON) in
            if(error?._code == 0){
                debugPrint("pool set protocol")
                completion(true,credReqJSON ?? "",credReqMetadataJSON ?? "",error)
            } else {
                completion(false,"", "" ,error)
            }
        }
    }
    
    func pool_prover_create_credential_request(walletHandle: IndyHandle, forCredentialOffer: String, credentialDefJSON: String, proverDID: String) async throws -> (Bool, String, String) {
        return try await withCheckedThrowingContinuation { continuation in
            pool_prover_create_credential_request(walletHandle: walletHandle, forCredentialOffer: forCredentialOffer, credentialDefJSON: credentialDefJSON, proverDID: proverDID) { result1, result2, result3, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2, result3))
            }
        }
    }
    
    
    @available(*, renamed: "pool_prover_store_credential(walletHandle:credentialModel:)")
    func pool_prover_store_credential(walletHandle: IndyHandle,credentialModel: SearchCertificateRecord,completion: @escaping(Bool,String,Error?) -> Void) {
        let credJson = UIApplicationUtils.shared.getJsonString(for: credentialModel.value?.rawCredential?.dictionary ?? [String:Any]())
        let credReqMetadataJSON = UIApplicationUtils.shared.getJsonString(for: credentialModel.value?.credentialRequestMetadata?.dictionary ?? [String:Any]())
        let credDefJSON = UIApplicationUtils.shared.getJsonString(for: credentialModel.value?.credDefJson?.dictionary ?? [String:Any]())
        AgentWrapper.shared.pool_prover_store_credential(credJson: credJson,
                                                         credID: credentialModel.value?.credentialID ?? AgentWrapper.shared.generateRandomId_BaseUID4(),
                                                         credReqMetadataJSON: credReqMetadataJSON,
                                                         credDefJSON: credDefJSON,
                                                         revRegDefJSON: nil,
                                                         walletHandle: walletHandle) { (error, outCredID) in
            if(error?._code == 0){
                debugPrint("pool set protocol")
                completion(true,outCredID ?? "",error)
            } else {
                completion(false,"" ,error)
            }
        }
    }
    
    func pool_prover_store_credential(walletHandle: IndyHandle,credentialModel: SearchCertificateRecord) async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            pool_prover_store_credential(walletHandle: walletHandle, credentialModel: credentialModel) { result1, result2, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    @available(*, renamed: "pool_prover_get_credential(id:walletHandle:)")
    func pool_prover_get_credential(id: String,walletHandle: IndyHandle,completion: @escaping(Bool,String,Error?) -> Void) {
        AgentWrapper.shared.pool_prover_get_credential(withId: id, walletHandle: walletHandle) { (error, credID) in
            if(error?._code == 0){
                debugPrint("pool set protocol")
                completion(true,credID ?? "",error)
            } else {
                completion(false,"" ,error)
            }
        }
    }
    
    func pool_prover_get_credential(id: String,walletHandle: IndyHandle) async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            pool_prover_get_credential(id: id, walletHandle: walletHandle) { result1, result2, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    @available(*, renamed: "pool_prover_get_credentials(forFilter:walletHandle:)")
    func pool_prover_get_credentials(forFilter: String!, walletHandle: IndyHandle, completion: @escaping ((Error?, String?) -> Void)) {
        AgentWrapper.shared.pool_prover_get_credentials(forFilter: forFilter, walletHandle: walletHandle) {(error, jsonString) in
            if(error?._code == 0){
                debugPrint("pool set protocol")
                completion(error, jsonString ?? "")
            } else {
                completion(error,"")
            }
        }
    }
    
    func pool_prover_get_credentials(forFilter: String!, walletHandle: IndyHandle) async throws-> (String?) {
        return try await withCheckedThrowingContinuation { continuation in
            pool_prover_get_credentials(forFilter: forFilter, walletHandle: walletHandle) { error, result2 in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result2))
            }
        }
    }
    
    
    func fetchAndSaveGenesis(completion: @escaping(String) -> Void){
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("genesis.txn") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                completion(filePath)
                return
            } else {
                debugPrint("FILE NOT AVAILABLE")
            }
        } else {
            debugPrint("FILE PATH NOT AVAILABLE")
        }
        
        if let genesis = coreDataManager.getAllGenesis(), genesis.isNotEmpty, let selectedLedger = coreDataManager.getCurrentGenesis() {
            if let genesis = self.saveGenesisToFile(string: selectedLedger.genesisString ) {
                completion(genesis)
            } else {
                completion(selectedLedger.genesisURL)
            }
        } else {
            self.getGenesisFromServerAndToCoreData(completion: completion)
        }
    }
    
    func getGenesisFromServerAndToCoreData(completion: @escaping (String) -> Void){
        NetworkManager.shared.get(service: .getGenesis, completion: { [weak self] (jsonData) in
            do {
                guard let data = jsonData else {
                    UIApplicationUtils.showErrorSnackbar(message: "Failed to fetch ledger list")
                    completion(Constants.ledger_default_path)
                    return
                }
                let genesisListModel = try JSONDecoder().decode([GenesisModel].self, from: data)
                self?.coreDataManager.addGenesis(model: genesisListModel){
                    if UserDefaults.standard.value(forKey: Constants.userDefault_ledger) == nil {
                        UserDefaults.standard.setValue(0, forKey:  Constants.userDefault_ledger)
                    }
                    if let genesis = self?.saveGenesisToFile(string: self?.coreDataManager.getCurrentGenesis()?.genesisString ?? "") {
                        completion(genesis)
                    } else {
                        completion(self?.coreDataManager.getCurrentGenesis()?.genesisURL ?? Constants.ledger_default_path)
                    }
                }
            } catch {
                // print error here.
                completion(Constants.ledger_default_path)
            }
        })
    }
    
    func saveGenesisToFile(string: String) -> String? {
        let filename = getDocumentsDirectory().appendingPathComponent("genesis.txn")
        do {
            try string.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
            debugPrint("File write successfully")
            return filename.path
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            return nil
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func stringToUnsafeMutablePointer(message: String) -> UnsafeMutablePointer<Int8> {
        var messageCString = message.utf8CString
        return messageCString.withUnsafeMutableBytes { mesUMRBP in
            return mesUMRBP.baseAddress!.bindMemory(to: Int8.self, capacity: mesUMRBP.count)
        }
        
    }
    
    func deleteDefaultPool(completion: @escaping(Bool,Error?) -> Void){
        AgentWrapper.shared.pool_delete(withName: "default") { (error) in
            if(error?._code == 0){
                debugPrint("delete default pool")
                completion(true,error)
            } else {
                completion(false,error)
            }
        }
    }
    
    func createDefaultPool(genesisPath: String,completion: @escaping(Bool,Error?) -> Void){
        
        let config = [
            "genesis_txn" : genesisPath
        ]
        AgentWrapper.shared.pool_create(withPoolName: "default", poolConfig: UIApplicationUtils.shared.getJsonString(for: config)) { (error) in
            if(error?._code == 0){
                debugPrint("create default pool")
                completion(true,error)
            } else {
                completion(false,error)
            }
        }
    }
    
    func createProof(forRequest: String, requestedCredentialsJSON: String, masterSecretID: String, schemasJSON: String, credentialDefsJSON: String, revocStatesJSON: String, walletHandle: IndyHandle, completion: @escaping ((Bool,String,Error?) -> Void)){
        AgentWrapper.shared.provercreateproof(forRequest: forRequest, requestedCredentialsJSON: requestedCredentialsJSON, masterSecretID: masterSecretID, schemasJSON: schemasJSON, credentialDefsJSON: credentialDefsJSON, revocStatesJSON: revocStatesJSON, walletHandle: walletHandle) { (error, proofJSON) in
            if(error?._code == 0){
                debugPrint("create default pool")
                completion(true,proofJSON ?? "",error)
            } else {
                completion(false,"",error)
            }
        }
        
    }
    
    func buildGetAcceptanceMechanismRequest(completion: @escaping(Bool,String,Error?) -> Void){
        
        AgentWrapper.shared.ledger_build_get_acceptance_mechanisms_request(withSubmitterDid: nil, timestamp: nil, version: nil) { (error, response) in
            if(error?._code == 0){
                debugPrint("build_get_acceptance_mechanisms_request")
                completion(true,response ?? "",error)
            } else {
                completion(false,"",error)
            }
        }
    }
    
    @available(*, renamed: "submitRequest(poolHandle:requestJSON:)")
    func submitRequest(poolHandle: IndyHandle, requestJSON: String,completion: @escaping(Bool,String,Error?) -> Void){
        
        AgentWrapper.shared.ledger_submitRequest(requestJSON: requestJSON, poolHandle: poolHandle) { (error, response) in
            if(error?._code == 0){
                debugPrint("submitRequest")
                completion(true,response ?? "",error)
            } else {
                completion(false,"",error)
            }
        }
    }
    
    func submitRequest(poolHandle: IndyHandle, requestJSON: String) async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            submitRequest(poolHandle: poolHandle, requestJSON: requestJSON) { result1, result2, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    func buildGetTxnAuthorAgreementRequest(completion: @escaping(Bool,String,Error?) -> Void){
        AgentWrapper.shared.ledger_build_get_txn_author_agreement_request(withSubmitterDid: nil, data: nil) { (error, response) in
            if(error?._code == 0){
                debugPrint("build_get_txn_author_agreement_request")
                completion(true,response ?? "",error)
            } else {
                completion(false,"",error)
            }
        }
    }
    
    @available(*, renamed: "buildGetCredDefRequest(id:)")
    func buildGetCredDefRequest(id: String,completion: @escaping(Bool,String,Error?) -> Void){
        AgentWrapper.shared.ledger_build_get_cred_definition_request(withSubmitterDid: nil, id: id) { (error, response) in
            if(error?._code == 0){
                debugPrint("build_get_cred_definition_request")
                completion(true,response ?? "",error)
            } else {
                completion(false,"",error)
            }
        }
    }
    
    func buildGetCredDefRequest(id: String) async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            buildGetCredDefRequest(id: id) { result1, result2, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    @available(*, renamed: "buildGetSchemaRequest(id:)")
    func buildGetSchemaRequest(id: String,completion: @escaping(Bool,String,Error?) -> Void){
        AgentWrapper.shared.ledger_build_get_schema_request(withSubmitterDid: nil, id: id) { (error, response) in
            if(error?._code == 0){
                debugPrint("build_get_cred_definition_request")
                completion(true,response ?? "",error)
            } else {
                completion(false,"",error)
            }
        }
    }
    
    func buildGetSchemaRequest(id: String) async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            buildGetSchemaRequest(id: id) { result1, result2, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    @available(*, renamed: "buildGetSchemaResponse(getSchemaResponse:)")
    func buildGetSchemaResponse(getSchemaResponse: String,completion: @escaping(Bool,String,String,Error?) -> Void){
        AgentWrapper.shared.ledger_build_get_schema_response(getSchemaResponse: getSchemaResponse) { (error, defID, defJson) in
            if(error?._code == 0){
                debugPrint("build_get_cred_definition_request")
                completion(true,defID ?? "",defJson ?? "",error)
            } else {
                completion(false,"","",error)
            }
        }
    }
    
    func buildGetSchemaResponse(getSchemaResponse: String) async throws -> (Bool, String, String) {
        return try await withCheckedThrowingContinuation { continuation in
            buildGetSchemaResponse(getSchemaResponse: getSchemaResponse) { result1, result2, result3, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2, result3))
            }
        }
    }
    
    
    @available(*, renamed: "parseGetCredDefResponse(response:)")
    func parseGetCredDefResponse(response: String,completion: @escaping(Bool,String,String,Error?) -> Void){
        AgentWrapper.shared.ledger_parse_get_cred_def_response(getCredDefResponse: response) { (error, credDefId, credDefJson) in
            
            if(error?._code == 0){
                debugPrint("parseGetCredDefResponse")
                completion(true,credDefId ?? "",credDefJson ?? "",error)
            } else {
                completion(false,"","",error)
            }
        }
    }
    
    func parseGetCredDefResponse(response: String) async throws -> (Bool, String, String) {
        return try await withCheckedThrowingContinuation { continuation in
            parseGetCredDefResponse(response: response) { result1, result2, result3, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2, result3))
            }
        }
    }
    
    
    func closePoolLedger(poolHandler: IndyHandle,completion: @escaping(Bool,Error?) -> Void){
        AgentWrapper.shared.pool_close_ledger(withHandle: poolHandler) { (error) in
            if(error?._code == 0){
                debugPrint("pool_close_ledger")
                completion(true,error)
            } else {
                completion(false,error)
            }
        }
    }
    
    func getCredentialsFromWallet(walletHandler: IndyHandle,completion: @escaping(Bool,String,Error?) -> Void){
        AgentWrapper.shared.pool_prover_search_credentials(forQuery: "{}", walletHandle: walletHandler) { (error, searchHandler, count) in
            AgentWrapper.shared.pool_prover_fetch_credentials(withSearchHandle: searchHandler, count: 100) { (error, records) in
                if(error?._code == 0){
                    debugPrint("getCredentialsFromWallet")
                    completion(true,records ?? "",error)
                } else {
                    completion(false,"",error)
                }
            }
        }
    }
    
    func deleteCredentialFromWallet(withId: String,walletHandle: IndyHandle, completion:@escaping (Bool,Error?)-> Void){
        AgentWrapper.shared.pool_prover_delete_credential(withId: withId, walletHandle: walletHandle) { (error) in
            if(error?._code == 0){
                debugPrint("delete Credential from wallet")
                completion(true,error)
            } else {
                completion(false,error)
            }
        }
    }
    
    func pool_prover_search_credentials(forProofRequest: String!, extraQueryJSON: String!, walletHandle: IndyHandle,completion: @escaping(Bool,IndyHandle?,Error?) -> Void){
        AgentWrapper.shared.pool_prover_search_credentials(forProofRequest: forProofRequest, extraQueryJSON: extraQueryJSON, walletHandle: walletHandle) { (error, searchHandle) in
            if(error?._code == 0){
                debugPrint("search credentials - proofreq")
                completion(true,searchHandle,error)
            } else {
                completion(false,searchHandle,error)
            }
        }
    }
    
    func proverfetchcredentialsforproof_req(forProofReqItemReferent: String!, searchHandle: IndyHandle, count: NSNumber!, completion: @escaping ((Bool, String?,Error?) -> Void)) {
        AgentWrapper.shared.pool_prover_fetch(forProofReqItemReferent: forProofReqItemReferent, searchHandle: searchHandle, count: count) { (error, response) in
            if(error?._code == 0){
                debugPrint("fetch credential - proof req")
                completion(true,response ?? "",error)
            } else {
                completion(false,"",error)
            }
        }
    }
    
    func proverclosecredentialssearchforproofreq(withHandle: IndyHandle, completion: @escaping ((Bool,Error?) -> Void)) {
        AgentWrapper.shared.pool_prover_close_credentialSearch_proofReq(withHandle: withHandle) { (error) in
            if(error?._code == 0){
                debugPrint("close proof search req")
                completion(true,error)
            } else {
                completion(false,error)
            }
        }
    }
}


//LedgerSwitching
extension AriesPoolHelper {
    
    func parseGetCredDefResponseWithLedgerSwitching(credentialDefinitionID: String, uncheckedLedgers: [GenesisModel]? = nil, triedLedgerCount: Int = 0) async -> (Bool,String,String,Error?){
        guard let walletHandler = WalletViewModel.openedWalletHandler else {
            return (false,"","",nil)
        }
        let allLedgers = await LedgerListViewController.ledgers
        var ledgers = uncheckedLedgers ?? allLedgers
        
        do {
            let (_, credDefReqResponse) = try await AriesPoolHelper.shared.buildGetCredDefRequest(id: credentialDefinitionID)
            let (_, credDefSubmitResponse) = try await AriesPoolHelper.shared.submitRequest(poolHandle: AriesPoolHelper.poolHandler, requestJSON: credDefReqResponse)
            let (cred_def_success, credDefId, credDefJson) = try await parseGetCredDefResponse(response: credDefSubmitResponse)
            return(cred_def_success,credDefId,credDefJson,nil)
            
        } catch (let error) {
            if error.localizedDescription.contains("309") {
                if let currentLedgerIndex = ledgers.firstIndex(where: { e in
                    e.id == CoreDataManager().getCurrentGenesis()?.id
                }) {
                    ledgers.remove(at: currentLedgerIndex)
                }
                if let ledger = ledgers.first{
                    debugPrint("Switching to ledger ..... \(ledger.str)")
                    UIApplicationUtils.showLoader(message: "Trying \(triedLedgerCount + 1) out of \(allLedgers.count)")
                    if AriesPoolHelper.shared.saveGenesisToFile(string: ledger.genesisString) != nil {
                        UserDefaults.standard.setValue(ledger.id, forKey: Constants.userDefault_ledger)
                        let success = await AriesPoolHelper.shared.configurePool(walletHandler: walletHandler)
                        if success ?? false {
                            let success = try? await AriesPoolHelper.shared.pool_setProtocol(version: 2)
                            let _ = try? await AriesPoolHelper.shared.pool_openLedger(name: "default", config: [String:Any]())
                            return await parseGetCredDefResponseWithLedgerSwitching(credentialDefinitionID: credentialDefinitionID,uncheckedLedgers: ledgers, triedLedgerCount: triedLedgerCount + 1)
                        } else {
                            return (false,"","",error)
                        }
                    }
                } else {
                    return (false,"","",error)
                }
            }
            return (false,"","",error)
        }
    }
    
    func getSchemaAndCredParsedListWithLedgerSwitching(credentialDefinitionID: String, uncheckedLedgers: [GenesisModel]? = nil, triedLedgerCount: Int = 0) async -> ([String], [String],Error?) {
        guard let walletHandler = WalletViewModel.openedWalletHandler else {
            return ([],[],nil)
        }
        var schemaParsedList: [String] = []
        var credParsedList: [String] = []
        let allLedgers = await LedgerListViewController.ledgers
        var ledgers = uncheckedLedgers ?? allLedgers
        
        do {
            let success = try? await AriesPoolHelper.shared.pool_setProtocol(version: 2)
            let _ = try? await AriesPoolHelper.shared.pool_openLedger(name: "default", config: [String:Any]())

            //get credentials --- let (getCredential_success,credentialJSON)
            let (_,credentialJSON) = try await AriesPoolHelper.shared.pool_prover_get_credential(id: credentialDefinitionID, walletHandle: walletHandler)
            let credentialDict = UIApplicationUtils.shared.convertToDictionary(text: credentialJSON)
            let credentialInfo = SearchProofReqCredInfo.decode(withDictionary: credentialDict as NSDictionary? ?? NSDictionary()) as? SearchProofReqCredInfo
            
            //get scheme request --- let (getSchemaReq_success, getSchemaReqResponse)
            let (_, getSchemaReqResponse) =  try await AriesPoolHelper.shared.buildGetSchemaRequest(id: credentialInfo?.schemaID ?? "")
            
            //submit request --- let (submitReq_success, submitResponse)
            let (_, submitResponse) =  try await AriesPoolHelper.shared.submitRequest(poolHandle: AriesPoolHelper.poolHandler, requestJSON: getSchemaReqResponse)
            
            //get scheme response ---  let (submitResponse_success, defId, defJson)
            let (_, _, defJson) =  try await AriesPoolHelper.shared.buildGetSchemaResponse(getSchemaResponse: submitResponse)
            if (!schemaParsedList.contains(defJson)){
                schemaParsedList.append(defJson)
            }
            
            //get credential definition request --- let (getCredDef_success, credReqResponse)
            let (_, credReqResponse) =  try await AriesPoolHelper.shared.buildGetCredDefRequest(id: credentialInfo?.credDefID ?? "")
            
            //submit request --- let (credDefRes_success, credDefResponse)
            let (_, credDefResponse) =  try await AriesPoolHelper.shared.submitRequest(poolHandle: AriesPoolHelper.poolHandler, requestJSON: credReqResponse)
            
            //parseGetCredDef --- let (parseCredDefRes_success, credId, credresJson)
            let (_, _, credresJson,error) = await AriesPoolHelper.shared.parseGetCredDefResponseWithLedgerSwitching(credentialDefinitionID: credentialInfo?.credDefID ?? "")
            credParsedList.append(credresJson)
            debugPrint("credResJSON added")
            return (schemaParsedList,credParsedList, error)
        } catch (let error) {
            if error.localizedDescription.contains("309") {
                if let currentLedgerIndex = ledgers.firstIndex(where: { e in
                    e.id == CoreDataManager().getCurrentGenesis()?.id
                }) {
                    ledgers.remove(at: currentLedgerIndex)
                }
                if let ledger = ledgers.first{
                    debugPrint("Switching to ledger ..... \(ledger.str)")
                    UIApplicationUtils.showLoader(message: "Trying \(triedLedgerCount + 1) out of \(allLedgers.count)")
                    if AriesPoolHelper.shared.saveGenesisToFile(string: ledger.genesisString) != nil {
                        UserDefaults.standard.setValue(ledger.id, forKey: Constants.userDefault_ledger)
                        let success = await AriesPoolHelper.shared.configurePool(walletHandler: walletHandler)
                        if success ?? false {
                            return await getSchemaAndCredParsedListWithLedgerSwitching(credentialDefinitionID: credentialDefinitionID,uncheckedLedgers: ledgers, triedLedgerCount: triedLedgerCount + 1)
                        } else {
                            return ([],[],error)
                        }
                    }
                } else {
                    return ([],[],error)
                }
            }
            return ([],[],error)
        }
    }
    
    func saveCredentialToWalletWithAutoLedgerSwitch(certModel: SearchCertificateRecord, uncheckedLedgers: [GenesisModel]? = nil, triedLedgerCount: Int = 0) async -> (Bool, String, Error?){
        guard let walletHandler = WalletViewModel.openedWalletHandler else {
            return (false,"",nil)
        }
        let allLedgers = await LedgerListViewController.ledgers
        var ledgers = uncheckedLedgers ?? allLedgers
        let success = try? await AriesPoolHelper.shared.pool_setProtocol(version: 2)
        let _ = try? await AriesPoolHelper.shared.pool_openLedger(name: "default", config: [String : Any]())
        do {
            let (_, outCredID) = try await AriesPoolHelper.shared.pool_prover_store_credential(walletHandle: walletHandler, credentialModel: certModel)
            let (success3, credID) = try await AriesPoolHelper.shared.pool_prover_get_credential(id: outCredID, walletHandle: walletHandler)
            return (success3, credID,nil)
        }catch (let error){
            if error.localizedDescription.contains("309") {
                if let currentLedgerIndex = ledgers.firstIndex(where: { e in
                    e.id == CoreDataManager().getCurrentGenesis()?.id
                }) {
                    ledgers.remove(at: currentLedgerIndex)
                }
                if let ledger = ledgers.first{
                    debugPrint("Switching to ledger ..... \(ledger.str)")
                    UIApplicationUtils.showLoader(message: "Trying \(triedLedgerCount + 1) out of \(allLedgers.count)")
                    if AriesPoolHelper.shared.saveGenesisToFile(string: ledger.genesisString) != nil {
                        UserDefaults.standard.setValue(ledger.id, forKey: Constants.userDefault_ledger)
                        let success = await AriesPoolHelper.shared.configurePool(walletHandler: walletHandler)
                        if success ?? false {
                            return await saveCredentialToWalletWithAutoLedgerSwitch(certModel: certModel, uncheckedLedgers: ledgers, triedLedgerCount: triedLedgerCount + 1)
                        } else {
                            return (false,"",error)
                        }
                    }
                } else {
                    return (false,"",error)
                }
            }
            return (false,"",error)
        }
       
    }
    
}
