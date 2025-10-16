//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 10/09/25.
//

import Foundation

open class MigrationCheck {
    
    func isMigrationRequired(migrationType: String) -> Bool {
        let defaults = UserDefaults.standard
        return !defaults.bool(forKey: migrationType)
    }
    
    func setMigrationCompleted(migrationType: String) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: migrationType)
    }
    
}

struct MigrationTypes {
    static let indyCredentialsToSelfAttestedOpenIdCredential = "IndyCredentialsToSelfAttestedOpenIdCredential"
    static let indyConnectionsToSelfAttestedOpenIdConnection = "IndyConnectionsToSelfAttestedOpenIdConnection"
}



//class IndyCredentialsToSelfAttestedOpenIDCredentials {
//    private let TAG = "IndyCredentialsToSelfAttestedOpenIDCredentials"
//    
//    func migrate() {
//        // 1. Check if migration is required
//        if !MigrationCheck().isMigrationRequired(.indyCredentialsToSelfAttestedOpenIdCredential) {
//            print("\(TAG): Migration from Indy credentials to self-attested OpenID credentials has already been performed.")
//            return
//        }
//        
//        // 2. Fetch Indy credentials from wallet
//        let indyCredentials = fetchIndyCredentials()
//        if indyCredentials.isEmpty {
//            print("\(TAG): indy credentials is empty.")
//            return
//        }
//        
//        // 3. Transform them
//        guard let transformedCredentials = transformToSelfAttestedOpenIDCredentials(indyCredentials: indyCredentials),
//              !transformedCredentials.isEmpty else {
//            print("\(TAG): self-attested OpenID transformed credentials are empty.")
//            return
//        }
//        
//        // 4. Store transformed credentials
//        storeSelfAttestedOpenIDCredentials(credentials: transformedCredentials)
//        
//        // 5. Delete old Indy credentials
//        deleteIndyCredentials(credentials: indyCredentials)
//    }
//    
//    private func fetchIndyCredentials() -> [WalletModel] {
//        var list: [WalletModel] = []
//        let credentialList = SearchUtils.searchWallet(
//            WALLET,
//            "{ \"type\":\"\(WalletRecordType.certificateTypeCredentials)\"}"
//        )
//        list.append(contentsOf: parseArray(credentialList.records ?? []))
//        return list
//    }
//    
//    private func transformToSelfAttestedOpenIDCredentials(indyCredentials: [WalletModel]?) -> [WalletModel]? {
//        var transformedWalletModels: [WalletModel] = []
//        
//        for indyCredential in indyCredentials ?? [] {
//            let credentialDisplay = CredentialDisplay(
//                name: indyCredential.searchableText,
//                logo: indyCredential.organizationV2?.logoImageUrl.flatMap {
//                    $0.isEmpty ? nil : Image(url: $0, altText: "Logo")
//                },
//                backgroundImage: indyCredential.organizationV2?.coverImageUrl.flatMap {
//                    $0.isEmpty ? nil : Image(url: $0, altText: "Logo")
//                },
//                description: indyCredential.organizationV2?.description
//            )
//            
//            let selfAttestedBindingConnection =
//                SelfAttestedOpenIdConverter.createOrFetchDIDForSelfAttestedCredential()
//            
//            let json = WalletManager.getGson().toJson(indyCredential)
//            let credentialSubject = fetchCredentialSubject(json: json)
//            
//            // Build self-attested OpenID credential
//            let response = SelfAttestedOpenIdCredentials.buildSelfAttestedOpenIdCredential(
//                credentialSubject: credentialSubject,
//                credentialIssuerId: selfAttestedBindingConnection.did,
//                jwk: selfAttestedBindingConnection.subJwk,
//                type: WalletRecordType.certificateTypeSelfAttested
//            )
//            
//            Task {
//                await fetchOrCreateConnectionBasedOnIndyConnection(indyCredential: indyCredential)
//            }
//            
//            if let response = response {
//                if let walletModel = SelfAttestedPassportConverter.convertIndyCredentialToWalletModel(
//                    response,
//                    credentialType: WalletRecordType.certificateTypeSelfAttested,
//                    indyCredential.credentialId,
//                    credentialDisplay
//                ) {
//                    transformedWalletModels.append(walletModel)
//                }
//            }
//        }
//        
//        return transformedWalletModels.isEmpty ? nil : transformedWalletModels
//    }
//    
//    private func fetchOrCreateConnectionBasedOnIndyConnection(indyCredential: WalletModel) async {
//        let display = Display(
//            name: indyCredential.organizationV2?.organisationName ?? "",
//            location: indyCredential.organizationV2?.location ?? "",
//            cover: Image(
//                url: indyCredential.organizationV2?.coverImageUrl ?? "",
//                altText: "CoverImage"
//            ),
//            logo: Image(
//                url: indyCredential.organizationV2?.logoImageUrl ?? "",
//                altText: "LogoImage"
//            ),
//            description: indyCredential.organizationV2?.description ?? ""
//        )
//        
//        // delete existing indy connection
//        deleteExistingIndyConnectionUsingConnectionName(connectionName: indyCredential.connection?.requestId)
//        
//        saveEbsiConnection(
//            createEbsiConnection(display: display, CryptographicAlgorithms.es256),
//            nil,
//            isGeneralConnection: display.name.isEmpty,
//            WalletManager.getGson().fromJson(WalletManager.getGson().toJson(display), Display.self),
//            clientId: "ebsi-\(indyCredential.credentialId)",
//            nil,
//            nil
//        )
//    }
//    
//    private func storeSelfAttestedOpenIDCredentials(credentials: [WalletModel]?) {
//        do {
//            for credential in credentials ?? [] {
//                let walletModelTag = """
//                {
//                  "type":"\(WalletRecordType.certificateTypeSelfAttested)",
//                  "sub_type":"\(WalletRecordType.certificateTypeSelfAttested)",
//                  "connection_id":"",
//                  "credential_id":"\(credential.credentialId)",
//                  "schema_id":""
//                }
//                """
//                
//                WalletMethods.addWalletRecord(
//                    WalletManager.getWallet(),
//                    WALLET,
//                    credential.credentialId,
//                    WalletManager.getGson().toJson(credential),
//                    walletModelTag
//                )
//                
//                // save to history
//                saveDataShareHistory(
//                    credential.connection,
//                    nil,
//                    nil,
//                    nil,
//                    [credential],
//                    presentationDefinition: nil
//                )
//            }
//            MigrationCheck().setMigrationCompleted(.indyCredentialsToSelfAttestedOpenIdCredential)
//        } catch {
//            print("Exception storeSelfAttestedOpenIDCredentials: \(error.localizedDescription)")
//        }
//    }
//    
//    private func deleteIndyCredentials(credentials: [WalletModel]?) {
//        credentials?.forEach { credential in
//            do {
//                try WalletRecord.delete(
//                    WalletManager.getWallet(),
//                    WALLET,
//                    credential.credentialId
//                ).get()
//            } catch {
//                print("Exception deleteIndyCredentials: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func fetchCredentialSubject(json: String) -> [String: Any] {
//        var result: [String: Any] = [:]
//        do {
//            if let data = json.data(using: .utf8),
//               let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//               let proposalDict = root["credential_proposal_dict"] as? [String: Any],
//               let credentialProposal = proposalDict["credential_proposal"] as? [String: Any],
//               let attributes = credentialProposal["attributes"] as? [[String: Any]] {
//                
//                for attr in attributes {
//                    if let name = attr["name"] as? String,
//                       let value = attr["value"] as? String {
//                        result[name] = value
//                    }
//                }
//            }
//        } catch {
//            print("Error parsing credential subject: \(error.localizedDescription)")
//        }
//        return result
//    }
//    
//    private func deleteExistingIndyConnectionUsingConnectionName(connectionName: String?) {
//        do {
//            guard let connectionName = connectionName else { return }
//            let connectionSearch = SearchUtils.searchWallet(
//                WalletRecordType.connection,
//                "{\"request_id\":\"\(connectionName)\"}"
//            )
//            if (connectionSearch.totalCount ?? 0) > 0 {
//                try WalletRecord.delete(
//                    WalletManager.getWallet(),
//                    WalletRecordType.connection,
//                    connectionSearch.records?.first?.id ?? ""
//                ).get()
//            }
//        } catch {
//            print("Exception deleteExistingIndyConnectionUsingConnectionName: \(error.localizedDescription)")
//        }
//    }
//}
