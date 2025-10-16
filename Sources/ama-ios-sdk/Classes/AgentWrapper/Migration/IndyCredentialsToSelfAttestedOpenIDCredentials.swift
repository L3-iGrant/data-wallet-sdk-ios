//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 09/09/25.
//

import Foundation
import CryptoKit
import eudiWalletOidcIos
import IndyCWrapper

public class IndyCredentialsToSelfAttestedOpenIDCredentials {
    
    public init() {}
    
    public func migrate() {
        // 1. Check if migration already done
//        Task {
            if !MigrationCheck().isMigrationRequired(migrationType: MigrationTypes.indyCredentialsToSelfAttestedOpenIdCredential) {
                print(" Migration from Indy credentials to self-attested OpenID credentials has already been performed.")
                return
            }
            
            // 2. Fetch Indy credentials
            //var indyCredentials: Search_CustomWalletRecordCertModel? = nil
            fetchIndyCredentials2 { data in
                Task {
                    let indyCredentials = data
                    
                    if indyCredentials == nil {
                        print(" Indy credentials are empty.")
                        return
                    }
                    
                    // 3. Transform them
                    guard let transformedCredentials = await self.transformToSelfAttestedOpenIDCredentials(indyCredentials),
                          transformedCredentials.records?.isEmpty == false else {
                        print(" Self-attested OpenID transformed credentials are empty.")
                        return
                    }
                    
                    // 4. Store transformed
                    self.storeSelfAttestedOpenIDCredentials(transformedCredentials)
                    
                    // 5. Delete Indy credentials
                    self.deleteIndyCredentials(indyCredentials)
                }
            }
//        }
        
    }
    
    public func fetchIndyCredentials2(completion: @escaping (Search_CustomWalletRecordCertModel?) -> Void) {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        
        AriesAgentFunctions.shared.openWalletSearch_type(
            walletHandler: walletHandler,
            type: AriesAgentFunctions.walletCertificates,
            searchType: .withoutQuery
        ) { [weak self] success, searchHandler, error in
            
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(
                walletHandler: walletHandler,
                searchWalletHandler: searchHandler
            ) { [weak self] fetched, response, error in
                
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let certSearchModel = Search_CustomWalletRecordCertModel.decode(
                    withDictionary: responseDict as NSDictionary? ?? NSDictionary()
                ) as? Search_CustomWalletRecordCertModel
                var output: [SearchItems_CustomWalletRecordCertModel]? = []
                //var indyCredentials: Search_CustomWalletRecordCertModel.init()
                for data in certSearchModel?.records ?? [] {
                    guard data.value?.certInfo != nil else { continue }
                    output?.append(data)
                }

                let indyCredentials = Search_CustomWalletRecordCertModel(totalCount: output?.count, records: output)
                completion(indyCredentials)
            }
        }
    }
    
    func fetchConnection(id: String) async -> CloudAgentConnectionWalletModel? {
        var connectionModel: CloudAgentConnectionWalletModel? = nil
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        do {
           
            let (success2, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(
                walletHandler: walletHandler,
                type: AriesAgentFunctions.cloudAgentConnection,
                searchType: .searchWithId,
                searchValue: id
            )
            if success2 {
                let (fetchedSuccessfully, results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(
                    walletHandler: walletHandler,
                    searchWalletHandler: searchWalletHandler
                )
                if fetchedSuccessfully {
                    print(results)
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                    if let firstResult = (resultDict?["records"] as? [[String: Any]])?.first {
                        connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstResult as NSDictionary? ?? NSDictionary()) as? CloudAgentConnectionWalletModel
                        //return connectionModel
                    }
                }
            }
        } catch {
            return nil
        }
        return connectionModel
    }
    
    // MARK: - Step 2: Transform to Self-Attested
    private func transformToSelfAttestedOpenIDCredentials(_ indyCredentials: Search_CustomWalletRecordCertModel?) async -> Search_CustomWalletRecordCertModel? {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        var transformedWalletModelsRecords: [SearchItems_CustomWalletRecordCertModel]? = []
//        Task {
            for indyCredential in indyCredentials?.records ?? [] {
                var connectionModel: CloudAgentConnectionWalletModel? = nil
                //var newConnection:  CloudAgentConnectionWalletModel? = nil
                connectionModel = indyCredential.value?.connectionInfo
               
//                await fetchOrCreateConnectionBasedOnIndyConnection(connectionModel) { id in
//                    Task {
//                            newConnection = await self.fetchConnection(id: id)
                        
                        let privateKey = SelfAttestedToOpenID().getPrivateKeyOfOpenIDPassport()
                        //let selfAttestedBindingConnection = await SelfAttestedToOpenID().createDIDforPassportIssuance(privateKey: privateKey)
                        let credentialSubject = self.fetchCredentialSubject(indyCredential.value?.certInfo?.value?.credentialProposalDict?.credentialProposal?.attributes ?? [] )
                       
                        let customWalletModel = CustomWalletRecordCertModel()
                        customWalletModel.type = "self_attested"
                        let schemeSeperated = indyCredential.value?.schemaID?.split(separator: ":")
                        let text = "\(schemeSeperated?[2] ?? "")".uppercased()
                        customWalletModel.subType = text
                        customWalletModel.searchableText = text
                        customWalletModel.headerFields = DWHeaderFields(title: text, subTitle: "", desc: "")
                        var vpToken = ""
                       // await SelfAttestedToOpenID.shared.configDID()
                        //let ebsiConnectionModel = await SelfAttestedToOpenID.shared.getPassportIssuanceConnection()
                        let DID = connectionModel?.value?.myDid ?? ""
                        let header =
                        ([
                            "alg": "ES256",
                            "kid": "\(DID)#\(DID.replacingOccurrences(of: "did:key:", with: ""))",
                            "typ": "dc+sd-jwt"
                        ]).toString() ?? ""
                        let sdData = SelfAttestedToOpenID.shared.credentialSubjectToDisclosureArray(credentialSubject: credentialSubject)
                        let currentTime = Int(Date().timeIntervalSince1970)
                        let uuid = UUID().uuidString
                        let startDate = Date()
                        var dateAfterAYear = Date(timeInterval: 365*86400, since: startDate)
                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                        df.timeZone = TimeZone(abbreviation: "UTC")
                        let dateAfterAYearStr = df.string(from: dateAfterAYear)
                        dateAfterAYear = df.date(from: dateAfterAYearStr) ?? Date()
                        let startDateStr = df.string(from: startDate)
                        // Generate JWT payload
                        let payload =
                        ([
                            "exp": currentTime + 1314000,
                            "iat": currentTime,
                            "iss": DID,
                            "jti": "urn:did:\(uuid)",
                            "nbf": currentTime,
                            "sub": DID,
                            "_sd": sdData.sdList,
                            "vct": "" 
                        ] as [String : Any]).toString() ?? ""
                        
                        let headerData = Data(header.utf8)
                        let payloadData = Data(payload.utf8)
                        let unsignedToken = "\(headerData.base64URLEncodedString()).\(payloadData.base64URLEncodedString())"
                        let signatureData = try? privateKey.signature(for: unsignedToken.data(using: .utf8)!)
                        let signature = signatureData?.rawRepresentation ?? Data()
                        vpToken = "\(unsignedToken).\(signature.base64URLEncodedString())"
                        
                        for data in sdData.disclosureList {
                            vpToken.append("~\(data)")
                        }
                        
                        let attributes = SelfAttestedOpenIDCredential().convertToOutputFormat(data : credentialSubject)
                        customWalletModel.referent = nil
                        customWalletModel.schemaID = nil
                        customWalletModel.certInfo = nil
                        customWalletModel.connectionInfo = connectionModel
                        customWalletModel.type = CertType.EBSI.rawValue
                        customWalletModel.format = ""
                        
                        //customWalletModel.vct = vct
                        customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: "", credentialJWT: vpToken)
                        
                        
                        
                        let itemData = SearchItems_CustomWalletRecordCertModel()
                        itemData.value = customWalletModel
                        transformedWalletModelsRecords?.append(itemData)
//                        }
//                }

            }
        return Search_CustomWalletRecordCertModel(totalCount: transformedWalletModelsRecords?.count, records: transformedWalletModelsRecords)
    }
    
    // MARK: - Step 3: Create or fetch connection
    private func fetchOrCreateConnectionBasedOnIndyConnection(_ connection: CloudAgentConnectionWalletModel?, completion: @escaping (String) -> ()) async {
        do {
            var orgDetail = OrganisationInfoModel.init()
          
            let display = Display(mName: connection?.value?.orgDetails?.name, mLocation: connection?.value?.orgDetails?.location, mLocale: "", mDescription: connection?.value?.orgDetails?.organisationInfoModelDescription, mCover: DisplayCover(mUrl: connection?.value?.orgDetails?.coverImageURL, mAltText: connection?.value?.orgDetails?.name), mLogo: DisplayCover(mUrl: connection?.value?.orgDetails?.logoImageURL, mAltText: connection?.value?.orgDetails?.name), mBackgroundColor: nil, mTextColor: nil)
            let imageURL =  display.cover?.url ?? ""
            orgDetail.orgId = connection?.value?.orgDetails?.orgId
            orgDetail.logoImageURL = display.logo?.url ?? display.logo?.uri
            orgDetail.coverImageURL = display.cover?.url
            orgDetail.location = display.location
            orgDetail.organisationInfoModelDescription = display.description
            orgDetail.name = display.name
            
            await deleteExistingIndyConnectionUsingConnectionName(connectionModel: connection)
            let privateKey = EBSIWallet.shared.handlePrivateKey()
            let did = await EBSIWallet.shared.createDIDKeyIdentifierForDynamicOrg(privateKey: privateKey) ?? ""
            let (_, connID) = try await WalletRecord.shared.add(invitationKey: "", label: display.name ?? "", serviceEndPoint: "", connectionRecordId: "",imageURL: imageURL, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),type: .connection, orgID: orgDetail.orgId)
            completion(connID)
        } catch {
            
        }
            
    }
    
    //check if connection migration needed
    func deleteExistingConnectionUsingConnectionName(walletHandler: IndyHandle, connectionName: String?, orgId: String?, completion: @escaping (Bool) -> Void) {
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithOrgId,searchValue: orgId ?? "") { (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (success, response, error) in
                if let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response){
                    guard let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) else { return }
                    
                    let connectionModels = Connections.decode(withDictionary: messageModel as [String : Any]) as? Connections
                    let filteredRecord = connectionModels?.records.filter({ $0.value.orgID == connectionName })
                    AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, id: filteredRecord?.first?.value.requestID ?? "") { (deleteSuccess, error) in
                        if deleteSuccess {
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }
                }else {
                    completion(false)
                }
            }
        }
    }
//    
//    // MARK: - Step 4: Store transformed credentials
    private func storeSelfAttestedOpenIDCredentials(_ credentials: Search_CustomWalletRecordCertModel?) {
        do {
            Task {
                let walletHandler = WalletViewModel.openedWalletHandler ?? 0
                for credential in credentials?.records ?? [] {
                    
                    let (success, certRecordId) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: credential.value, walletHandler: walletHandler, type: .walletCert)
                    
                }
                MigrationCheck().setMigrationCompleted(migrationType: MigrationTypes.indyCredentialsToSelfAttestedOpenIdCredential)
            }
        }  catch {
            print("Exception storeSelfAttestedOpenIDCredentials: \(error.localizedDescription)")
        }
    }
//
//    // MARK: - Step 5: Delete old Indy credentials
    private func deleteIndyCredentials(_ credentials: Search_CustomWalletRecordCertModel?) {
        credentials?.records?.forEach { credential in
            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
            
            AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: credential.id ?? "") { [weak self](success, error) in
                
                print("")
            }
        }
    }
//
//    // MARK: - Helpers
    func fetchCredentialSubject(_ attributes: [SearchCertificateAttribute]) -> [String: Any] {
        var result: [String: Any] = [:]
        
        for attr in attributes {
            if let name = attr.name,
               let value = attr.value {
                result[name] = value
            }
        }
        return result
    }
    
    func deleteExistingIndyConnectionUsingConnectionName(
        connectionModel: CloudAgentConnectionWalletModel?
    ) async {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var numberOfBlockCompleted = 0
            let expectedBlocks = 5
            
            func blockCompleted() {
                numberOfBlockCompleted += 1
                if numberOfBlockCompleted == expectedBlocks {
                    //  Once all 5 blocks done, delete connection + invitation
                    let reqId = connectionModel?.value?.requestID ?? ""
                    AriesAgentFunctions.shared.deleteWalletRecord(
                        walletHandler: walletHandler,
                        type: AriesAgentFunctions.cloudAgentConnection,
                        id: reqId
                    ) { success, error in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            UIApplicationUtils.hideLoader()
                            continuation.resume()
                        }
                    }
                }
            }
            
            // 🔹 delete didDoc
            AriesAgentFunctions.shared.openWalletSearch_type(
                walletHandler: walletHandler,
                type: DidDocTypes.cloudAgentDidDoc.rawValue,
                searchType: .searchWithTheirDid,
                searchValue: connectionModel?.value?.theirDid ?? ""
            ) { success, searchHandler, error in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(
                    walletHandler: walletHandler,
                    searchWalletHandler: searchHandler,
                    count: 1
                ) { success, response, error in
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                    let didDocModel = SearchDidDocModel.decode(
                        withDictionary: resultDict as NSDictionary? ?? NSDictionary()
                    ) as? SearchDidDocModel
                    AriesAgentFunctions.shared.deleteWalletRecord(
                        walletHandler: walletHandler,
                        type: DidDocTypes.cloudAgentDidDoc.rawValue,
                        id: didDocModel?.records?.first?.value?.id ?? ""
                    ) { success, error in
                        print("delete didDoc")
                        blockCompleted()
                    }
                }
            }
            
            // 🔹 delete didKey
            AriesAgentFunctions.shared.openWalletSearch_type(
                walletHandler: walletHandler,
                type: DidKeyTypes.cloudAgentDidKey.rawValue,
                searchType: .searchWithTheirDid,
                searchValue: connectionModel?.value?.theirDid ?? ""
            ) { success, searchHandler, error in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(
                    walletHandler: walletHandler,
                    searchWalletHandler: searchHandler,
                    count: 1
                ) { success, response, error in
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                    let record = (resultDict?["records"] as? [[String: Any]])?.first
                    let id = (record?["value"] as? [String: Any])?["@id"] as? String ?? ""
                    AriesAgentFunctions.shared.deleteWalletRecord(
                        walletHandler: walletHandler,
                        type: DidKeyTypes.cloudAgentDidKey.rawValue,
                        id: id
                    ) { success, error in
                        print("delete didKey")
                        blockCompleted()
                    }
                }
            }
            
            // 🔹 delete certType
            AriesAgentFunctions.shared.openWalletSearch_type(
                walletHandler: walletHandler,
                type: AriesAgentFunctions.certType,
                searchType: .searchWithId,
                searchValue: connectionModel?.value?.requestID ?? ""
            ) { success, searchHandler, error in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(
                    walletHandler: walletHandler,
                    searchWalletHandler: searchHandler,
                    count: 1000
                ) { success, result, error in
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: result)
                    let certificatedModel = SearchCertificateResponse.decode(
                        withDictionary: resultDict as NSDictionary? ?? NSDictionary()
                    ) as? SearchCertificateResponse
                    if certificatedModel?.totalCount == 0 {
                        print("delete certType (empty)")
                        blockCompleted()
                        return
                    }
                    var count = 0
                    for item in certificatedModel?.records ?? [] {
                        AriesAgentFunctions.shared.deleteWalletRecord(
                            walletHandler: walletHandler,
                            type: AriesAgentFunctions.inbox,
                            id: item.id ?? ""
                        ) { success, error  in
                            count += 1
                            if count == certificatedModel?.records?.count {
                                print("delete certType")
                                blockCompleted()
                            }
                        }
                    }
                }
            }
            
            // 🔹 delete presentationExchange
            AriesAgentFunctions.shared.openWalletSearch_type(
                walletHandler: walletHandler,
                type: AriesAgentFunctions.presentationExchange,
                searchType: .searchWithId,
                searchValue: connectionModel?.value?.requestID ?? ""
            ) { success, searchHandler, error in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(
                    walletHandler: walletHandler,
                    searchWalletHandler: searchHandler,
                    count: 1000
                ) { success, result, error in
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: result)
                    let presentationExchangeModel = SearchPresentationExchangeModel.decode(
                        withDictionary: resultDict as NSDictionary? ?? NSDictionary()
                    ) as? SearchPresentationExchangeModel
                    if presentationExchangeModel?.totalCount == 0 {
                        print("delete presentationExchange (empty)")
                        blockCompleted()
                        return
                    }
                    var count = 0
                    for item in presentationExchangeModel?.records ?? [] {
                        AriesAgentFunctions.shared.deleteWalletRecord(
                            walletHandler: walletHandler,
                            type: AriesAgentFunctions.inbox,
                            id: item.id ?? ""
                        ) { success, error  in
                            count += 1
                            if count == presentationExchangeModel?.records?.count {
                                print("delete presentationExchange")
                                blockCompleted()
                            }
                        }
                    }
                }
            }
            
            // 🔹 delete notifications
            AriesAgentFunctions.shared.openWalletSearch_type(
                walletHandler: walletHandler,
                type: AriesAgentFunctions.inbox,
                searchType: .searchWithId,
                searchValue: connectionModel?.value?.requestID ?? ""
            ) { success, searchHandler, error in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(
                    walletHandler: walletHandler,
                    searchWalletHandler: searchHandler,
                    count: 1000
                ) { success, result, error in
                    let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: result)
                    let searchInboxModel = SearchInboxModel.decode(
                        withDictionary: recordResponse as NSDictionary? ?? NSDictionary()
                    ) as? SearchInboxModel
                    if searchInboxModel?.totalCount == 0 {
                        print("delete notifications (empty)")
                        blockCompleted()
                        return
                    }
                    var count = 0
                    for item in searchInboxModel?.records ?? [] {
                        AriesAgentFunctions.shared.deleteWalletRecord(
                            walletHandler: walletHandler,
                            type: AriesAgentFunctions.inbox,
                            id: item.id ?? ""
                        ) { success, error in
                            count += 1
                            if count == searchInboxModel?.records?.count {
                                print("delete notifications")
                                blockCompleted()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deletedSuccessfully(count: Int, connectionInvitationRecordId: String?, reqId: String?){
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        if count != 5 {
            return
        }
        //delete Connection
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, id: reqId ?? "") { [weak self] (deletedSuccessfully, error) in
            //delete connection Invitation
            AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnectionInvitation, id: connectionInvitationRecordId ?? "") { [weak self](success, error) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    UIApplicationUtils.hideLoader()
                    
                })
            }
        }
    }

}

//public class IndyCredentialsToSelfAttestedOpenIDCredentials {
//    
//    func migrate() {
//        // 1. Check if migration has already been performed
//        if !MigrationCheck().isMigrationRequired(migrationType: MigrationTypes.indyCredentialsToSelfAttestedOpenIdCredential) {
//            print("Migration from Indy credentials to self-attested OpenID credentials has already been performed.")
//            return
//        }
//        
//        // 2. Fetch Indy credentials from the wallet
//        let indyCredentials = fetchIndyCredentials()
//        if indyCredentials.isEmpty {
//            print("Indy credentials are empty.")
//            return
//        }
//        
//        // 3. Transform into self-attested OpenID credentials
//        guard let transformedCredentials = transformToSelfAttestedOpenIDCredentials(indyCredentials),
//              !transformedCredentials.isEmpty else {
//            print("Self-attested OpenID transformed credentials are empty.")
//            return
//        }
//        
//        // 4. Store transformed credentials
//        storeSelfAttestedOpenIDCredentials(transformedCredentials)
//        
//        // 5. Delete old Indy credentials
//        deleteIndyCredentials(indyCredentials)
//    }
//    
//    // MARK: - Stub methods (you need to implement them)
//    private func fetchIndyCredentials() -> [String] {
//        // TODO: Replace with actual fetch logic
//        return []
//    }
//    
//    private func transformToSelfAttestedOpenIDCredentials(_ indyCredentials: [String]) -> [String]? {
//        // TODO: Replace with actual transformation logic
//        return nil
//    }
//    
//    private func storeSelfAttestedOpenIDCredentials(_ credentials: [String]) {
//        // TODO: Replace with actual storage logic
//    }
//    
//    private func deleteIndyCredentials(_ indyCredentials: [String]) {
//        // TODO: Replace with actual deletion logic
//    }
//    
//}
