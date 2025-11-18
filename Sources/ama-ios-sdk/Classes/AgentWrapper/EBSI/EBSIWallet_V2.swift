//
//  EBSIWallet_V2.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 01/08/22.
//

import Foundation
import Base58Swift
import qr_code_scanner_ios
import JOSESwift
import IndyCWrapper
import UIKit
import CryptoKit
import KeychainSwift
import eudiWalletOidcIos
import AuthenticationServices
import DeviceCheck

extension EBSIWallet {
    func configureWalletForV2EBSIversion(issuerCode: String, isFromShareData: Bool = false){
        Task{
            //Check if connection already exist
            var did = ""
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            
            if let connectionModel = await getEBSI_V2_connection() {
                // get did from existing EBSI_V2 connection
                did = connectionModel.value?.myDid ?? ""
            } else {
                let (connMdl,_,_) = await ConnectionPopupViewController.showConnectionPopupForEBSI(walletHandler: walletHandler, orgName: "EBSI", orgImageURL: "https://i.ibb.co/jwPYjLb/Screenshot-2022-06-29-152618.png", orgId: orgId, orgDetails: "EBSI is a joint initiative from the European Commission and the European Blockchain Partnership. The vision is to leverage blockchain to accelerate the creation of cross-border services for public administrations and their ecosystems to verify information and to make services more trustworthy.")
                guard let connectionModel = connMdl, let myDid = connectionModel.value?.myDid else { return}
                did = myDid
            }
            
            UIApplicationUtils.showLoader()
            let code_url = URL.init(string: issuerCode)
            let conformance = code_url?.queryParameters?["conformance"] as? String ?? ""
            let credential_type = code_url?.queryParameters?["credential_type"] as? String ?? ""
            let issuer = code_url?.queryParameters?["issuer"] as? String ?? ""
            
            //Authorize
            let authorization_details = EBSI_V2_Authorization_Details.init(type: "openid_credential", credentialType: credential_type, format: "jwt_vc")
            let url_params = [
                "scope": "openid conformance_testing",
                "response_type" : "code",
                "redirect_uri": redirect_uri,
                "client_id": did,
                "response_mode": "post",
                "state": hexStringOfRandom6Bytes(),
                "authorization_details": "[" + authorization_details.toString() + "]"
            ]
            var authorize_url_string = EBSIWallet.baseURL_V2 + "conformance/v2/issuer-mock/authorize"
            var authorize_url = URL.init(string: authorize_url_string)
            url_params.forEach { (e) in
                authorize_url = authorize_url?.appending(e.key, value: e.value)
            }
            authorize_url_string = authorize_url_string.replacingOccurrences(of: "?&", with: "?")
            
            let url = URL(string: authorize_url_string)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = url_params.map{
                return URLQueryItem(name: "\($0)", value: "\($1)")
            }
            urlComponents?.queryItems = queryItems
            debugPrint(urlComponents?.url?.absoluteString)
            
            let response = await NetworkManager.shared.EBSI_V2_authorize(url: urlComponents?.url?.absoluteString ?? "", conformance: conformance)
            debugPrint(response)
            guard let auth_response_URL = URL.init(string: response ?? "") else {return}
            let state = auth_response_URL.queryParameters?["state"] ?? ""
            let code = auth_response_URL.queryParameters?["code"] ?? ""
            
            
            //Token
            let tokenURL_string = EBSIWallet.baseURL_V2 + "conformance/v2/issuer-mock/token"
            let getTokenParam = [
                "code": code,
                "grant_type": "authorization_code",
                "redirect_uri": redirect_uri
            ]
            let (_, getTokenResponse) = await NetworkManager.shared.EBSI_sendMsg(param: getTokenParam, url: tokenURL_string, accessToken: "",contentType: "application/x-www-form-urlencoded", conformance: conformance)
            let jsonDecoder = JSONDecoder()
            guard let auth_response = try? jsonDecoder.decode(EBSIV2AuthTokenResponse.self, from: getTokenResponse ?? Data()) else { return }
            guard let EBSI_token = auth_response.idToken else {return}
            
            var model = EBSIConnectionNaturalPersonWalletModel.init()
            model.did = did
            model.desc = "EBSI is a joint initiative from the European Commission and the European Blockchain Partnership. The vision is to leverage blockchain to accelerate the creation of cross-border services for public administrations and their ecosystems to verify information and to make services more trustworthy."
            
            await self.issueCredential(did: did, issuer: issuer, credential_type: credential_type, conformance: conformance, authTokenModel: auth_response, isFromShareData: isFromShareData)
            
        }
    }
    
    func issueCredential(did: String, issuer: String, credential_type: String, conformance: String, authTokenModel: EBSIV2AuthTokenResponse, isFromShareData: Bool) async{
        defer{
            UIApplicationUtils.hideLoader()
        }
        // Receive issued credential
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        let c_nonce = authTokenModel.cNonce
        let access_token = authTokenModel.accessToken
        //        let did = getV2DID()
        //        let issuer = getEBSI_initiate_issuer()
        let jwk = getECPublicKey(did: did)?.parameters
        
        let jws_payload = [
            "nonce": c_nonce ?? "",
            "aud": issuer ,
            "iat": Int(Date().epochTime) ?? 0,
            "iss": did
        ] as [String : Any]
        
        let jwt_header = [
            "alg": "ES256K",
            "typ": "JWT",
            "kid": "\(did)#\(getThumbprint() ?? "")",
            "jwk": [
                "kty": "EC",
                "crv": "secp256k1",
                "x": jwk?["x"] ?? "",
                "y": jwk?["y"] ?? ""
            ]
        ] as [String : Any]
        
        let private_key = getPrivateKey()
        let jwt = EBSIUtils.signAndCreateJWTToken(payloadDict: jws_payload, header: jwt_header, privateKey: private_key)
        let credential_url = EBSIWallet.baseURL_V2 + "conformance/v2/issuer-mock/credential"
        let param = [
            "type": credential_type ,
            "proof": [
                "proof_type": "jwt",
                "jwt": jwt ?? ""
            ]
        ] as! [String : Any]
        
        let (statuscode, issue_response) = await NetworkManager.shared.EBSI_sendMsg(param: param, url: credential_url, accessToken: access_token, contentType: "application/x-www-form-urlencoded", conformance: conformance)
        if statuscode != 200 {
            UIApplicationUtils.showErrorSnackbar(message: "Something went wrong".localizedForSDK())
            return
        }
        guard let responseModel = try? JSONSerialization.jsonObject(with: issue_response ?? Data(), options: []) as? [String : Any] else { return }
        debugPrint(responseModel)
        let jsonDecoder = JSONDecoder()
        guard let issueResponseModel = try? jsonDecoder.decode(EBSIV2IssueCredentialResponse.self, from: issue_response ?? Data()) else { return }
        let credential_jwt = issueResponseModel.credential ?? ""
        let credential_jwt_parts = credential_jwt.split(separator: ".")
        let credential_jwt_payload = "\(credential_jwt_parts[safe: 1] ?? "")"
        let credential = credential_jwt_payload.decodeBase64() ?? ""
        let dict = UIApplicationUtils.shared.convertToDictionary(text: credential) ?? [:]
        guard let connectionModel = await getEBSI_V2_connection() else { return}
        debugPrint(credential)
        
        if let credentialModel = EBSI_V2_VerifiableID.decode(withDictionary: dict as [String : Any]) as? EBSI_V2_VerifiableID {
            let customWalletModel = CustomWalletRecordCertModel.init()
            if let data = credentialModel.vc?.credentialSubject?.achieved?.first {
                //Diploma
                let attributes = [
                    IDCardAttributes.init(name: "Scheme ID", value: data.identifier?.first?.schemeID),
                    IDCardAttributes.init(name: "Value", value: data.identifier?.first?.value),
                    IDCardAttributes.init(name: "Eqfl Level", value: data.specifiedBy?.first?.eqflLevel),
                    IDCardAttributes.init(name: "Title", value: data.specifiedBy?.first?.title),
                    IDCardAttributes.init(name: "Awarding Location", value: data.wasAwardedBy?.awardingLocation?.first),
                    IDCardAttributes.init(name: "Awarding Date", value: data.wasAwardedBy?.awardingDate),
                    IDCardAttributes.init(name: "Awarding Body", value: data.wasAwardedBy?.awardingBody?.first),
                    IDCardAttributes.init(name: "id", value: data.wasAwardedBy?.id)
                ]
                customWalletModel.referent = nil
                customWalletModel.schemaID = nil
                customWalletModel.certInfo = nil
                customWalletModel.connectionInfo = connectionModel
                customWalletModel.type = CertType.EBSI.rawValue
                customWalletModel.subType = EBSI_CredentialType.Diploma.rawValue
                customWalletModel.searchableText = EBSI_CredentialSearchText.Diploma.rawValue
                customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel.iss, credentialJWT: credential_jwt)
                //                let (success, id) = try? await WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .walletCert)
            } else if let data = credentialModel.vc?.credentialSubject?.identifier?.first {
                //Student ID
                let attributes = [
                    IDCardAttributes.init(name: "Scheme ID", value: data.schemeID),
                    IDCardAttributes.init(name: "Value", value: data.value),
                    IDCardAttributes.init(name: "Id", value: credentialModel.vc?.credentialSubject?.id ?? "", schemeID: "ID"),
                ]
                customWalletModel.referent = nil
                customWalletModel.schemaID = nil
                customWalletModel.certInfo = nil
                customWalletModel.connectionInfo = connectionModel
                customWalletModel.type = CertType.EBSI.rawValue
                customWalletModel.subType = EBSI_CredentialType.StudentID.rawValue
                customWalletModel.searchableText = EBSI_CredentialSearchText.StudentID.rawValue
                customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel.iss, credentialJWT: credential_jwt)
            }
            else if let section1 = credentialModel.vc?.credentialSubject?.section1,
                    let section2 = credentialModel.vc?.credentialSubject?.section2,
                    let section3 = credentialModel.vc?.credentialSubject?.section3,
                    let section4 = credentialModel.vc?.credentialSubject?.section4,
                    let section5 = credentialModel.vc?.credentialSubject?.section5,
                    let section6 = credentialModel.vc?.credentialSubject?.section6 {
                
                let attributes = [
                    //Section 1
                    IDCardAttributes.init(name: "Personal Identification Number", value: section1.personalIdentificationNumber, schemeID: "personalIdentificationNumber"),
                    IDCardAttributes.init(name: "Sex", value: section1.sex, schemeID: "sex"),
                    IDCardAttributes.init(name: "Surname", value: section1.surname, schemeID: "surname"),
                    IDCardAttributes.init(name: "Forenames", value: section1.forenames, schemeID: "forenames"),
                    IDCardAttributes.init(name: "DateBirth", value: section1.dateBirth, schemeID: "dateBirth"),
                    IDCardAttributes.init(name: "Nationalities", value: section1.nationalities?.first, schemeID: "nationalities"),
                    IDCardAttributes.init(name: "State Of Residence Address", value: section1.stateOfResidenceAddress?.addressToString(), schemeID: "stateOfResidenceAddress"),
                    IDCardAttributes.init(name: "State Of Stay Address", value: section1.stateOfStayAddress?
                        .addressToString(), schemeID: "stateOfStayAddress"),
                    
                    //Section 2
                    IDCardAttributes.init(name: "Member State Which Legislation Applies", value: section2.memberStateWhichLegislationApplies, schemeID: "memberStateWhichLegislationApplies"),
                    IDCardAttributes.init(name: "Starting Date", value: section2.startingDate, schemeID: "startingDate"),
                    IDCardAttributes.init(name: "Ending Date", value: section2.endingDate, schemeID: "endingDate"),
                    IDCardAttributes.init(name: "Certificate For Duration Activity", value: section2.certificateForDurationActivity?.toString(), schemeID: "certificateForDurationActivity"),
                    IDCardAttributes.init(name: "Determination Provisional", value: section2.determinationProvisional?.toString(), schemeID: "determinationProvisional"),
                    IDCardAttributes.init(name: "Transition Rules Apply As EC8832004", value: section2.transitionRulesApplyAsEC8832004?.toString(), schemeID: "transitionRulesApplyAsEC8832004"),
                    
                    //Section 3
                    IDCardAttributes.init(name: "Posted Employed Person", value: section3.postedEmployedPerson?.toString(), schemeID: "postedEmployedPerson"),
                    IDCardAttributes.init(name: "Employed Two Or More States", value: section3.employedTwoOrMoreStates?.toString(), schemeID: "employedTwoOrMoreStates"),
                    IDCardAttributes.init(name: "Posted Self Employed Person", value: section3.postedSelfEmployedPerson?.toString(), schemeID: "postedSelfEmployedPerson"),
                    IDCardAttributes.init(name: "Self Employed Two Or More States", value: section3.selfEmployedTwoOrMoreStates?.toString(), schemeID: "selfEmployedTwoOrMoreStates"),
                    IDCardAttributes.init(name: "Civil Servant", value: section3.civilServant?.toString(), schemeID: "civilServant"),
                    IDCardAttributes.init(name: "Contract Staff", value: section3.contractStaff?.toString(), schemeID: "contractStaff"),
                    IDCardAttributes.init(name: "Mariner", value: section3.mariner?.toString(), schemeID: "mariner"),
                    IDCardAttributes.init(name: "Employed And Self Employed", value: section3.employedAndSelfEmployed?.toString(), schemeID: "employedAndSelfEmployed"),
                    IDCardAttributes.init(name: "Civil And Employed Self Employed", value: section3.civilAndEmployedSelfEmployed?.toString(), schemeID: "civilAndEmployedSelfEmployed"),
                    IDCardAttributes.init(name: "Flight Crew Member", value: section3.flightCrewMember?.toString(), schemeID: "flightCrewMember"),
                    IDCardAttributes.init(name: "Exception", value: section3.exception?.toString(), schemeID: "exception"),
                    IDCardAttributes.init(name: "Exception Description", value: section3.exceptionDescription, schemeID: "exceptionDescription"),
                    IDCardAttributes.init(name: "Working In State Under 21", value: section3.workingInStateUnder21?.toString(), schemeID: "workingInStateUnder21"),
                    
                    //Section 4
                    IDCardAttributes.init(name: "Employee", value: section4.employee?.toString(), schemeID: "employee"),
                    IDCardAttributes.init(name: "Self Employed Activity", value: section4.selfEmployedActivity?.toString(), schemeID: "selfEmployedActivity"),
                    IDCardAttributes.init(name: "Name Business Name", value: section4.nameBusinessName, schemeID: "nameBusinessName"),
                    IDCardAttributes.init(name: "Registered Address", value: section4.registeredAddress?.addressToString(), schemeID: "registeredAddress"),
                    
                    //Section 5
                    IDCardAttributes.init(name: "No Fixed Address", value: section5.noFixedAddress?.toString(), schemeID: "noFixedAddress"),
                    
                    //Section 6
                    IDCardAttributes.init(name: "Name", value: section6.name, schemeID: "name"),
                    IDCardAttributes.init(name: "Address", value: section6.address?.addressToString(), schemeID: "address"),
                    IDCardAttributes.init(name: "Institution ID", value: section6.institutionID, schemeID: "institutionID"),
                    IDCardAttributes.init(name: "Office Fax No", value: section6.officeFaxNo, schemeID: "officeFaxNo"),
                    IDCardAttributes.init(name: "Office Phone No", value: section6.officePhoneNo, schemeID: "officePhoneNo"),
                    IDCardAttributes.init(name: "Email", value: section6.email, schemeID: "email"),
                    IDCardAttributes.init(name: "Date", value: section6.date, schemeID: "date"),
                    IDCardAttributes.init(name: "Signature", value: section6.signature, schemeID: "signature"),
                    
                ]
                
                let sectionStruct = [
                    DWSection(title: "Personal Details", key: "section1"),
                    DWSection(title: "Member State Legislation", key: "section2"),
                    DWSection(title: "Status Confirmation", key: "section3"),
                    DWSection(title: "Employment Details", key: "section4"),
                    DWSection(title: "Activity Employment Details", key: "section5"),
                    DWSection(title: "Completing Institution", key: "section6")
                ]
                
                var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
                for (index,attr) in attributes.enumerated() {
                    switch index {
                    case 0...7:
                        let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[0].key ?? "")
                        attributeStructure[key] = value
                    case 8...13:
                        let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[1].key ?? "")
                        attributeStructure[key] = value
                    case 14...26: let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[2].key ?? "")
                        attributeStructure[key] = value
                    case 27...30: let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[3].key ?? "")
                        attributeStructure[key] = value
                    case 31: let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[4].key ?? "")
                        attributeStructure[key] = value
                    case 32...:
                        let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[5].key ?? "")
                        attributeStructure[key] = value
                    default:break
                        
                    }
                }
                
                customWalletModel.attributes = attributeStructure
                customWalletModel.sectionStruct = sectionStruct
                customWalletModel.referent = nil
                customWalletModel.schemaID = nil
                customWalletModel.certInfo = nil
                customWalletModel.connectionInfo = connectionModel
                customWalletModel.type = CertType.EBSI.rawValue
                customWalletModel.subType = EBSI_CredentialType.PDA1.rawValue
                customWalletModel.searchableText = EBSI_CredentialSearchText.PDA1.rawValue
                customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel.iss, credentialJWT: credential_jwt)
                
                
            }
            else {
                //Verifier ID
                let data = credentialModel.vc?.credentialSubject
                let attributes = [
                    IDCardAttributes.init(name: "Personal Identifier", value: data?.personalIdentifier, schemeID: "PersonalIdentifier"),
                    IDCardAttributes.init(name: "First Name", value: data?.firstName, schemeID: "FirstName"),
                    IDCardAttributes.init(name: "Family Name", value: data?.familyName, schemeID: "FamilyName"),
                    IDCardAttributes.init(name: "Date Of Birth", value: data?.dateOfBirth, schemeID: "DateOfBirth"),
                    IDCardAttributes.init(name: "Id", value: data?.id, schemeID: "ID"),
                ]
                customWalletModel.referent = nil
                customWalletModel.schemaID = nil
                customWalletModel.certInfo = nil
                customWalletModel.connectionInfo = connectionModel
                customWalletModel.type = CertType.EBSI.rawValue
                customWalletModel.subType = EBSI_CredentialType.VerifiableID.rawValue
                customWalletModel.searchableText = EBSI_CredentialSearchText.VerifiableID.rawValue
                customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel.iss, credentialJWT: credential_jwt)
            }
            
            if isFromShareData {
                do {
                    let (_, _) = try await WalletRecord.shared.add(connectionRecordId: "",walletCert: customWalletModel, connectionModel: connectionModel, walletHandler: walletHandler, type: .inbox_EBSIOffer)
                    //SDK
                    //UIApplicationUtils.showSuccessSnackbar(message: "Received offer credential".localizedForSDK(),navToNotifScreen:true)
                    AriesMobileAgent.shared.delegate?.notificationReceived(message: "Received offer credential".localizedForSDK())
                    return
                } catch {
                    debugPrint(error.localizedDescription)
                    return
                }
            } else {
                DispatchQueue.main.async {
                    var searchModel = SearchItems_CustomWalletRecordCertModel.init()
                    searchModel.value = customWalletModel
                    if let controller = UIStoryboard(name:"ama-ios-sdk", bundle: Bundle.module).instantiateViewController( withIdentifier: "CertificatePreviewViewController") as? CertificatePreviewViewController {
                        controller.viewModel = CertificatePreviewViewModel.init(walletHandle: walletHandler, reqId: "", certDetail: nil, inboxId: "", certModel: searchModel, connectionModel: connectionModel,dataAgreement: nil)
                        controller.mode = .EBSI_V2
                        if customWalletModel.subType == EBSI_CredentialType.PDA1.rawValue {
                            controller.mode = .EBSI_PDA1
                        }
                        if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController{
                            navVC.pushViewController(controller, animated: true)
                        } else{
                            UIApplicationUtils.shared.getTopVC()?.push(vc: controller)
                        }
                    }
                }
            }
            
        }
    }
    
    func verifyCredential(credential: CustomWalletRecordCertModel, conformance: String?) async -> Bool {
        defer{
            UIApplicationUtils.hideLoader()
        }
        
        UIApplicationUtils.showLoader()
        //            let url_params = [
        //                "redirect": "undefined"
        //            ]
        let authentication_requests_url = EBSIWallet.baseURL_V2 + "conformance/v2/verifier-mock/authentication-requests?redirect=undefined"
        let response = await NetworkManager.shared.EBSI_V2_authentication_requests(url: authentication_requests_url, conformance: conformance)
        guard let request_responseModel = String.init(data: response ?? Data(), encoding: .utf8) else { return false}
        debugPrint(request_responseModel )
        
        guard let auth_response_URL = URL.init(string: request_responseModel ?? "") else {return false}
        var did = ""
        if let connectionModel = await getEBSI_V2_connection() {
            // get did from existing EBSI_V2 connection
            did = connectionModel.value?.myDid ?? ""
        }
        
        //Create verifiable presentation as JWT
        let credetialJWT = credential.EBSI_v2?.credentialJWT
        let jti = "urn:did:\(AgentWrapper.shared.generateRandomId_BaseUID4())"
        let iat = Int(Date().epochTime) ?? 0
        let jwt_payload = [
            "jti": jti,
            "sub": did,
            "iss": did,
            "nbf": iat - 7,
            "exp": iat + 900,
            "iat": iat,
            "aud": credential.EBSI_v2?.issuer ?? "",
            "vp": [
                "id": jti,
                "@context": [
                    "https://www.w3.org/2018/credentials/v1"
                ],
                "type": [
                    "VerifiablePresentation"
                ],
                "holder": did,
                "verifiableCredential": [
                    credetialJWT
                ]
            ]
        ] as [String : Any]
        var jwk = getECPublicKey(did: did)?.parameters
        let jwt_header = [
            "alg": "ES256K",
            "typ": "JWT",
            "kid": "\(did)#\(getThumbprint() ?? "")",
            "jwk": [
                "kty": "EC",
                "crv": "secp256k1",
                "x": jwk?["x"] ?? "",
                "y": jwk?["y"] ?? ""
            ]
        ] as [String : Any]
        
        let private_key = getPrivateKey()
        let vp_jwt = EBSIUtils.signAndCreateJWTToken(payloadDict: jwt_payload, header: jwt_header, privateKey: private_key)
        
        //Construct id_token JWT
        
        let id_token_payload = [
            "_vp_token": [
                "presentation_submission": [
                    "id": "\(AgentWrapper.shared.generateRandomId_BaseUID4())",
                    "definition_id": "conformance_mock_vp_request",
                    "descriptor_map": [
                        [
                            "id": "conformance_mock_vp",
                            "format": "jwt_vp",
                            "path": "$"
                        ]
                    ]
                ]
            ]
        ]
        
        let id_token_jwk = getECPublicKey(did: did)?.parameters
        let id_token_jwt_header = [
            "alg": "ES256K",
            "typ": "JWT",
            "kid": "\(did)#\(getThumbprint() ?? "")",
            "jwk": [
                "kty": "EC",
                "crv": "secp256k1",
                "x": id_token_jwk?["x"] ?? "",
                "y": id_token_jwk?["y"] ?? ""
            ]
        ] as [String : Any]
        
        let id_token = EBSIUtils.signAndCreateJWTToken(payloadDict: id_token_payload, header: id_token_jwt_header, privateKey: private_key)
        
        //Send authentication response with verifiable presentation in the payload
        let authentication_response_url = EBSIWallet.baseURL_V2 + "conformance/v2/verifier-mock/authentication-responses"
        
        let param = [
            "id_token" : id_token ?? "",
            "vp_token" : vp_jwt ?? ""
        ]
        let response_verify = await NetworkManager.shared.EBSI_V2_verify(url: authentication_response_url, param: param, conformance: conformance)
        guard let verify_responseModel = try? JSONSerialization.jsonObject(with: response_verify ?? Data(), options: []) as? [String : Any] else { return false}
        debugPrint(verify_responseModel)
        
        if let success = verify_responseModel["result"] as? Bool {
            return success
        } else {
            return false
        }
    }
    
    func getEBSI_V2_connection() async -> CloudAgentConnectionWalletModel? {
        do {
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithOrgId,searchValue: orgId)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            guard let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) else { return nil}
            let records = messageModel["records"] as? [[String:Any]]
            guard let firstRecord = records?.first as NSDictionary? else {return nil}
            let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord) as? CloudAgentConnectionWalletModel
            return connectionModel
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    func createV2DID() -> String {
        do {
            let thumbprintBase64URLEncoded = getThumbprint() ?? ""
            let thumbPrintBase64 = thumbprintBase64URLEncoded.base64urlToBase64() // Data.init(base64URLEncoded: thumbprintBase64URLEncoded) ?? Data()
            let decodedThumbPrint = try Base64.decode(thumbPrintBase64)
            
            let methodPrefix = "did:ebsi:";
            var version = 0x02;
            var bytesArray: Data = Data() //  Uint8Array(1 + byteLength);
            bytesArray.append(Data(bytes: &version,
                                   count: 1));
            bytesArray.append(Data(bytes: decodedThumbPrint,
                                   count: decodedThumbPrint.count));
            let methodSpecificIdentifier = Base58.base58Encode([UInt8](bytesArray))//  base58btc.encode(bytesArray);
            let did =  methodPrefix + "z" + methodSpecificIdentifier
            debugPrint("Generated DID ---- > \(did)")
            return did
        } catch {
            debugPrint(error.localizedDescription)
            return ""
        }
    }
    
    func clearCacheAfterIssuanceAndExchange(){
        openIdIssuerResponseData = nil
    }
    
    
//    func openIdAuthorisation(authServerUrl: String,privateKey: P256.Signing.PrivateKey, isNotAPinError : @escaping (Bool?) -> Void) async {
//        
////        Task{
//            do{
//                let authConfig = try await DiscoveryService.shared.getAuthConfig(authorisationServerWellKnownURI: authServerUrl)
//                
//                if authConfig?.error != nil {
//                    debugPrint("error!:\(authConfig?.error?.message ?? "")")
//                } else {
//                    
//                    _ = authConfig?.authorizationEndpoint ?? ""
//                    globalDID = await createDIDKeyIdentifierForV3(privateKey: privateKey) ?? ""
//                    _ = "http://localhost:8080"
//                    _ =  credentialIssuer
//                    _ = issuerState
//                    _ = credentialTypes
//                    let tokenEndpoint = authConfig?.tokenEndpoint ?? ""
//                    tokenEndpointForConformanceFlow = tokenEndpoint
//                    authServerUrlString = authServerUrl
//                    jwksUrlString = authConfig?.jwksURI
//                    privateKeyData = privateKey
//                    let formatT = issueHandler?.getFormatFromIssuerConfig(issuerConfig: self.openIdIssuerResponseData, type: credentialTypes.last)
//
//
//                    if (preAuthCode != "") {
//                        if let codeVerifier = CodeVerifierService.shared.generateCodeVerifier() {
//                            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
//                            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation,searchType: .withoutQuery) { (success, searchHandler, error) in
//                                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [self] (fetched, response, error) in
//                                    let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
//                                    let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
//                                    Task {
//                                        let keyHandler = SecureEnclaveHandler(keyID: keyIDforWUA)
//                                        let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
//                                        let pop = await WalletUnitAttestationService().generateWUAProofOfPossession(keyHandler: keyHandler, aud: credentialOffer?.credentialIssuer)
//                                        let clientIDAssertion = await WalletUnitAttestationService().createClientAssertion(aud: credentialOffer?.credentialIssuer ?? "", keyHandler: keyHandler)
//                                        let redirectURI = "openid://datawallet"
//                                        let accessTokenResponse = await issueHandler?.processTokenRequest(did: did, tokenEndPoint: tokenEndpoint, code: preAuthCode, codeVerifier: codeVerifier, isPreAuthorisedCodeFlow: true, userPin: otpVal, version: self.credentialOffer?.version, clientIdAssertion: clientIDAssertion, wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT ?? "", pop: pop, redirectURI: redirectURI)
//                                        if accessTokenResponse?.error != nil{
//                                            DispatchQueue.main.async {
//                                                UIApplicationUtils.hideLoader()
//                                                UIApplicationUtils.showErrorSnackbar(message: accessTokenResponse?.error?.message ?? "connection_unexpected_error_please_try_again".localized())
//                                            }
//                                        } else if accessTokenResponse?.accessToken == nil {
//                                            UIApplicationUtils.hideLoader()
//                                            isNotAPinError(false)
//                                        }else {
//                                            
//                                            let nonce = await NonceServiceUtil().fetchNonce(accessTokenResponse: accessTokenResponse, nonceEndPoint: openIdIssuerResponseData?.nonceEndPoint)
//                                            isNotAPinError(true)
//                                            await requestCredentialUsingEbsiV3(didKeyIdentifier: globalDID, c_nonce: nonce ?? "", accessToken: accessTokenResponse?.accessToken ?? "", privateKey: privateKey, authServerURL: authServerUrl, jwkUri: authConfig?.jwksURI, refreshToken: accessTokenResponse?.refreshToken ?? "", tokenEndPoint: authConfig?.tokenEndpoint ?? "", authDetails: accessTokenResponse?.authorizationDetails, tokenResponse: accessTokenResponse, credentialOffer: credentialOffer, issuerConfig: self.openIdIssuerResponseData)
//                                        }
//                                    }
//                                }
//                            }
//                            ////
//                        
//                            ////
//                        }
//                    } else {
//                        let privateKey = handlePrivateKey()
//                        if let authConfig,
//                           let credentialOffer,
//                           let codeVerifier = CodeVerifierService.shared.generateCodeVerifier(){
//                            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
//                            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation,searchType: .withoutQuery) { (success, searchHandler, error) in
//                                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [self] (fetched, response, error) in
//                                    let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
//                                    let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
//                                    Task {
//                                        codeVerifierCreated = codeVerifier
//                                        let docType = issueHandler?.getDocTypeFromIssuerConfig(issuerConfig: self.openIdIssuerResponseData, type: credentialTypes.last)
//                                        let keyHandler = SecureEnclaveHandler(keyID: self.keyIDforWUA)
//                                        let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
//                                        let pop = await WalletUnitAttestationService().generateWUAProofOfPossession(keyHandler: keyHandler, aud: credentialOffer.credentialIssuer)
//                                        authConfigData = authConfig
//                                        var isAPiCallRequired: Bool? = false
//                                        if credentialOffer.credentials?.first?.types?.last?.contains("WalletUnitAttestation") == true || credentialOffer.version == "v1" {
//                                            isAPiCallRequired = true
//                                        }
//                                        isAPiCallRequired = true
//                                        let authorisationRespone = await issueHandler?.processAuthorisationRequest(did: did, credentialOffer: credentialOffer, codeVerifier: codeVerifier, authServer: authConfig, credentialFormat: formatT ?? "", docType: docType ?? "", issuerConfig: self.openIdIssuerResponseData, redirectURI: webRedirectURI, isApiCallRequired: true, wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT ?? "", pop: pop)
//                                        print(authorisationRespone ?? "")
//                                        var queryItems: [URLQueryItem]? = nil
//                                        
//                                        if let url = URL(string: authorisationRespone?.data ?? "") {
//                                            queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
//                                        }
//                                        if queryItems?.first(where: { $0.name == "type" })?.value == "redirect_to_web" {
//                                            if let authURL = URL(string: authorisationRespone?.data ?? "") {
//                                                //startWebAuthentication(url: authURL, redirectURI: webRedirectURI, authorisationResponeData: authorisationRespone?.data, authorisationResponeError: authorisationRespone?.error, codeVerifier: codeVerifier, tokenEndpoint: tokenEndpoint, authServerUrl: authServerUrl, jwkUri: authConfig.jwksURI, privateKey: privateKey)
//                                            } else {
//                                                UIApplicationUtils.hideLoader()
//                                                UIApplicationUtils.showErrorSnackbar(message: "connection_unexpected_error_please_try_again".localized())
//                                                return
//                                            }
//                                        } else {
//                                            if queryItems?.first(where: { $0.name == "code" }) == nil &&
//                                                !(authorisationRespone?.data?.hasPrefix(webRedirectURI) ?? false) &&
//                                                (authorisationRespone?.data?.hasPrefix("http") == true || authorisationRespone?.data?.hasPrefix("https") == true) && queryItems?.first(where: { $0.name == "type" })?.value != "openid4vp_presentation" {
//                                                guard let urlString = authorisationRespone?.data,
//                                                      let url = URL(string: urlString),
//                                                      UIApplication.shared.canOpenURL(url) else {
//                                                    UIApplicationUtils.hideLoader()
//                                                    UIApplicationUtils.showErrorSnackbar(message: "connection_unexpected_error_please_try_again".localized())
//                                                    return
//                                                }
//                                                //startWebAuthentication(url: url, redirectURI: webRedirectURI, authorisationResponeData: authorisationRespone?.data, authorisationResponeError: authorisationRespone?.error, codeVerifier: codeVerifier, tokenEndpoint: tokenEndpoint, authServerUrl: authServerUrl, jwkUri: authConfig.jwksURI, privateKey: privateKey)
//                                            } else if queryItems?.first(where: { $0.name == "code" }) == nil &&
//                                                        queryItems?.first(where: { $0.name == "presentation_definition_uri" }) == nil &&
//                                                        queryItems?.first(where: { $0.name == "request_uri" }) == nil &&
//                                                        queryItems?.first(where: { $0.name == "presentation_definition" }) == nil && queryItems?.first(where: { $0.name == "type" })?.value != "openid4vp_presentation"{
//                                                if !(authorisationRespone?.data?.hasPrefix(webRedirectURI) ?? false){
//                                                    guard let urlString = authorisationRespone?.data,
//                                                          let url = URL(string: urlString),
//                                                          UIApplication.shared.canOpenURL(url) else {
//                                                        UIApplicationUtils.hideLoader()
//                                                        UIApplicationUtils.showErrorSnackbar(message: "connection_unexpected_error_please_try_again".localized())
//                                                        return
//                                                    }
//                                                    //startWebAuthentication(url: url, redirectURI: webRedirectURI, authorisationResponeData: authorisationRespone?.data, authorisationResponeError: authorisationRespone?.error, codeVerifier: codeVerifier, tokenEndpoint: tokenEndpoint, authServerUrl: authServerUrl, jwkUri: authConfig.jwksURI, privateKey: privateKey)
//                                                } else {
//                                                    handleAuthorizationResponse(authorisationResponeData: authorisationRespone?.data, authorisationResponeError: authorisationRespone?.error, codeVerifier: codeVerifier, tokenEndpoint: authConfig?.tokenEndpoint ?? "", authServerUrl: authServerUrl, jwkUri: authConfig.jwksURI, privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: self.openIdIssuerResponseData)
//                                                }
//                                            } else {
//                                                handleAuthorizationResponse(authorisationResponeData: authorisationRespone?.data, authorisationResponeError: authorisationRespone?.error, codeVerifier: codeVerifier, tokenEndpoint: authConfig?.tokenEndpoint ?? "", authServerUrl: authServerUrl, jwkUri: authConfig.jwksURI, privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: issuerConfig)
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//
//                        }
//                    }
//                }
//            } catch {
//                UIApplicationUtils.hideLoader()
//                debugPrint("JSON Serialization error")
//            }
////        }
//    }
    
    
    
    
    
    
    
    
    
    
    //@available(iOS 14.0, *)
    func openIdAuthorisation(authServerUrl: String,privateKey: P256.Signing.PrivateKey, credentialOffer: CredentialOffer?, issuerConfig: IssuerWellKnownConfiguration?, isNotAPinError : @escaping (Bool?) -> Void) {
        
        Task{ 
            do{
                let authConfig = try await DiscoveryService.shared.getAuthConfig(authorisationServerWellKnownURI: authServerUrl)
                
                if authConfig?.error != nil {
                    debugPrint("error!:\(authConfig?.error?.message ?? "")")
                } else {
                    
                    globalDID = await createDIDKeyIdentifierForV3(privateKey: privateKey) ?? ""
                    _ = credentialTypes
                    let tokenEndpoint = authConfig?.tokenEndpoint ?? ""
                    tokenEndpointForConformanceFlow = tokenEndpoint
                    //let tokenEndpoint = authConfig?.tokenEndpoint ?? ""
                    //let jwksUrlString = authConfig?.jwksURI
                    authServerUrlString = authServerUrl
                    privateKeyData = privateKey
                    credentialTypes =  issueHandler?.getTypesFromCredentialOffer(credentialOffer: credentialOffer) ?? []
                    let formatT = issueHandler?.getFormatFromIssuerConfig(issuerConfig: issuerConfig, type: credentialTypes.last)

                    if (credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.preAuthorizedCode?.isNotEmpty == true) {
                        if let codeVerifier = CodeVerifierService.shared.generateCodeVerifier() {
                            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
                            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation,searchType: .withoutQuery) { (success, searchHandler, error) in
                                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [self] (fetched, response, error) in
                                    let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                                    let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                                    Task {
                                        let keyHandler = SecureEnclaveHandler(keyID: keyHandlerKeyID)
                                        let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
                                        let pop = await WalletUnitAttestationService().generateWUAProofOfPossession(keyHandler: keyHandler, aud: credentialOffer?.credentialIssuer)
                                        let clientIDAssertion = await WalletUnitAttestationService().createClientAssertion(aud: credentialOffer?.credentialIssuer ?? "", keyHandler: keyHandler)
                                        let redirectURI = "openid://datawallet"
                                        let accessTokenResponse = await issueHandler?.processTokenRequest(did: did, tokenEndPoint: authConfig?.tokenEndpoint ?? "", code: credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.preAuthorizedCode ?? "", codeVerifier: codeVerifier, isPreAuthorisedCodeFlow: true, userPin: otpVal, version: credentialOffer?.version, clientIdAssertion: clientIDAssertion, wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT ?? "", pop: pop, redirectURI: redirectURI)
                                        if accessTokenResponse?.error != nil{
                                            DispatchQueue.main.async {
                                                UIApplicationUtils.hideLoader()
                                                UIApplicationUtils.showErrorSnackbar(message: accessTokenResponse?.error?.message ?? "connection_unexpected_error_please_try_again".localized())
                                            }
                                        } else if accessTokenResponse?.accessToken == nil {
                                            UIApplicationUtils.hideLoader()
                                            isNotAPinError(false)
                                        }else {
                                            
                                            let nonce = await NonceServiceUtil().fetchNonce(accessTokenResponse: accessTokenResponse, nonceEndPoint: issuerConfig?.nonceEndPoint)
                                            isNotAPinError(true)
                                            await requestCredentialUsingEbsiV3(didKeyIdentifier: globalDID, c_nonce: nonce ?? "", accessToken: accessTokenResponse?.accessToken ?? "", privateKey: privateKey, authServerURL: authServerUrl, jwkUri: authConfig?.jwksURI, refreshToken: accessTokenResponse?.refreshToken ?? "", tokenEndPoint: authConfig?.tokenEndpoint ?? "", authDetails: accessTokenResponse?.authorizationDetails, tokenResponse: accessTokenResponse, credentialOffer: credentialOffer, issuerConfig: issuerConfig)
                                        }
                                    }
                                }
                            }
                            ////
                        
                            ////
                        }
                    } else {
                        let privateKey = handlePrivateKey()
                        if let authConfig,
                           let credentialOffer,
                           let codeVerifier = CodeVerifierService.shared.generateCodeVerifier(){
                            //let codeVerifierCreated = codeVerifier
                            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
                            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation,searchType: .withoutQuery) { (success, searchHandler, error) in
                                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [self] (fetched, response, error) in
                                    let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                                    let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                                    
                                    Task {
                                        codeVerifierCreated = codeVerifier
                                        let docType = issueHandler?.getDocTypeFromIssuerConfig(issuerConfig: issuerConfig, type: credentialTypes.last)
                                        let keyHandler = SecureEnclaveHandler(keyID: self.keyHandlerKeyID)
                                        let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
                                        authConfigData = authConfig
                                        var isAPiCallRequired: Bool? = false
                                        if credentialOffer.credentials?.first?.types?.last?.contains("WalletUnitAttestation") == true || credentialOffer.version == "v1" {
                                            isAPiCallRequired = true
                                        }
                                        let pop = await WalletUnitAttestationService().generateWUAProofOfPossession(keyHandler: keyHandler, aud: credentialOffer.credentialIssuer)
                                        let authorisationRespone = await issueHandler?.processAuthorisationRequest(did: did, credentialOffer: credentialOffer, codeVerifier: codeVerifier, authServer: authConfig, credentialFormat: formatT ?? "", docType: docType ?? "", issuerConfig: issuerConfig, redirectURI: webRedirectURI, isApiCallRequired: true, wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT ?? "", pop: pop)
                                        print(authorisationRespone ?? "")
                                        var queryItems: [URLQueryItem]? = nil
                                        
                                        if let url = URL(string: authorisationRespone?.data ?? "") {
                                            queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
                                        }
                                        if queryItems?.first(where: { $0.name == "type" })?.value == "redirect_to_web" {
                                            if let authURL = URL(string: authorisationRespone?.data ?? "") {
                                                startWebAuthentication(url: authURL, redirectURI: webRedirectURI, authorisationResponeData: authorisationRespone?.data, authorisationResponeError: authorisationRespone?.error, codeVerifier: codeVerifier, tokenEndpoint: tokenEndpoint, authServerUrl: authServerUrl, jwkUri: authConfig.jwksURI, privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: issuerConfig)
//                                                if let authURL = URL(string: authorisationRespone?.data ?? "") {
//                                                    DispatchQueue.main.async {
//                                                        UIApplication.shared.open(authURL, options: [:], completionHandler: nil)
//                                                    }
//                                                    
//                                                }
                                            } else {
                                                UIApplicationUtils.hideLoader()
                                                UIApplicationUtils.showErrorSnackbar(message: "connection_unexpected_error_please_try_again".localized())
                                                return
                                            }
                                        } else {
                                            if queryItems?.first(where: { $0.name == "code" }) == nil &&
                                                !(authorisationRespone?.data?.hasPrefix(webRedirectURI) ?? false) &&
                                                (authorisationRespone?.data?.hasPrefix("http") == true || authorisationRespone?.data?.hasPrefix("https") == true) && queryItems?.first(where: { $0.name == "type" })?.value != "openid4vp_presentation" {
                                                guard let urlString = authorisationRespone?.data,
                                                      let url = URL(string: urlString),
                                                      UIApplication.shared.canOpenURL(url) else {
                                                    UIApplicationUtils.hideLoader()
                                                    UIApplicationUtils.showErrorSnackbar(message: "connection_unexpected_error_please_try_again".localized())
                                                    return
                                                }
//                                                if let authURL = URL(string: authorisationRespone?.data ?? "") {
//                                                    DispatchQueue.main.async {
//                                                        UIApplication.shared.open(authURL, options: [:], completionHandler: nil)
//                                                    }
//                                                    
//                                                }
                                                startWebAuthentication(url: url, redirectURI: webRedirectURI, authorisationResponeData: authorisationRespone?.data, authorisationResponeError: authorisationRespone?.error, codeVerifier: codeVerifier, tokenEndpoint: tokenEndpoint, authServerUrl: authServerUrl, jwkUri: authConfig.jwksURI, privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: issuerConfig)
                                            } else if queryItems?.first(where: { $0.name == "code" }) == nil &&
                                                        queryItems?.first(where: { $0.name == "presentation_definition_uri" }) == nil &&
                                                        queryItems?.first(where: { $0.name == "request_uri" }) == nil &&
                                                        queryItems?.first(where: { $0.name == "presentation_definition" }) == nil && queryItems?.first(where: { $0.name == "type" })?.value != "openid4vp_presentation"{
                                                if !(authorisationRespone?.data?.hasPrefix(webRedirectURI) ?? false){
                                                    guard let urlString = authorisationRespone?.data,
                                                          let url = URL(string: urlString),
                                                          UIApplication.shared.canOpenURL(url) else {
                                                        UIApplicationUtils.hideLoader()
                                                        UIApplicationUtils.showErrorSnackbar(message: "connection_unexpected_error_please_try_again".localized())
                                                        return
                                                    }
                                                    startWebAuthentication(url: url, redirectURI: webRedirectURI, authorisationResponeData: authorisationRespone?.data, authorisationResponeError: authorisationRespone?.error, codeVerifier: codeVerifier, tokenEndpoint: tokenEndpoint, authServerUrl: authServerUrl, jwkUri: authConfig.jwksURI, privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: issuerConfig)
//                                                    if let authURL = URL(string: authorisationRespone?.data ?? "") {
//                                                        DispatchQueue.main.async {
//                                                            UIApplication.shared.open(authURL, options: [:], completionHandler: nil)
//                                                        }
//                                                        
//                                                    }
                                                } else {
                                                    handleAuthorizationResponse(authorisationResponeData: authorisationRespone?.data, authorisationResponeError: authorisationRespone?.error, codeVerifier: codeVerifier, tokenEndpoint: authConfig.tokenEndpoint ?? "", authServerUrl: authServerUrl, jwkUri: authConfig.jwksURI, privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: issuerConfig)
                                                }
                                            } else {
                                                handleAuthorizationResponse(authorisationResponeData: authorisationRespone?.data, authorisationResponeError: authorisationRespone?.error, codeVerifier: codeVerifier, tokenEndpoint: authConfig.tokenEndpoint ?? "", authServerUrl: authServerUrl, jwkUri: authConfig.jwksURI, privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: issuerConfig)
                                            }
                                        }
//
                                    }
                                }
                            }
                            
                        }
                    }
                }
            } catch {
                UIApplicationUtils.hideLoader()
                debugPrint("JSON Serialization error")
            }
        }
    }
    
    func startWebAuthentication(url: URL, redirectURI: String, authorisationResponeData: String?, authorisationResponeError: eudiWalletOidcIos.EUDIError?, codeVerifier: String, tokenEndpoint: String, authServerUrl: String, jwkUri: String?, privateKey: P256.Signing.PrivateKey,  credentialOffer: CredentialOffer?, issuerConfig: IssuerWellKnownConfiguration?) {
        let contextProvider = WebAuthPresentationContextProvider()
        webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: URL(string: redirectURI)?.scheme
        ) { callbackURL, error in
            if let error = error {
                if let authError = error as? ASWebAuthenticationSessionError,
                   authError.code == .canceledLogin {
                    print("Authentication cancelled by user.")
                    UIApplicationUtils.hideLoader()
                    return
                } else {
                    print("Authentication failed with error: \(error.localizedDescription)")
                    UIApplicationUtils.hideLoader()
                    UIApplicationUtils.showErrorSnackbar(
                        message: "connection_unexpected_error_please_try_again".localized()
                    )
                    return
                }
            }
            
            if let callbackURL = callbackURL {
                // Handle the redirect URL returned from the browser
                let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems
                
                self.handleAuthorizationResponse(authorisationResponeData: callbackURL.absoluteString, authorisationResponeError: authorisationResponeError, codeVerifier: codeVerifier, tokenEndpoint: tokenEndpoint, authServerUrl: authServerUrl, jwkUri: jwkUri, privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: issuerConfig)
            }
        }
        
        webAuthSession?.presentationContextProvider = contextProvider
        webAuthSession?.prefersEphemeralWebBrowserSession = true
        webAuthSession?.start()
    }
    
    //@available(iOS 14.0, *)
    func requestCredentialUsingEbsiV3(didKeyIdentifier: String, c_nonce: String, accessToken: String, privateKey: P256.Signing.PrivateKey, ebsiV3Exchange: Bool = false, is_SDJWT: Bool = false, authServerURL: String = "", jwkUri: String? = "", refreshToken: String, tokenEndPoint: String = "", authDetails: [AuthorizationDetails]? = nil, tokenResponse: TokenResponse? = nil, isPWA: Bool? = false, credentialOffer: CredentialOffer? = nil, issuerConfig: IssuerWellKnownConfiguration? = nil) async {
        do {
            if let responseModel = openIdIssuerResponseData {
                print("keyid value: \(self.keyIDforWUA)")
                let keyHandler = SecureEnclaveHandler(keyID: self.keyHandlerKeyID)
                let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
                let credentialTypes =  issueHandler?.getTypesFromCredentialOffer(credentialOffer: credentialOffer)
                if let credentials = EBSIWallet.shared.credentialOffer?.credentials {
                    for (index,credential) in credentials.enumerated() {
                        dynamicCredentialCount += 1
                        let format = issueHandler?.getFormatFromIssuerConfig(issuerConfig: responseModel, type: credentialTypes?.last)
                        let credentialDisplay2 = issueHandler?.getCredentialDisplayFromIssuerConfig(issuerConfig: responseModel, type: credential.types?.first)
                        let auth = tokenResponse?.authorizationDetails?.first(where: { $0.credentialConfigId == credential.types?.first})
                        let encryptionDetails = EncryptionKeyBuilder().build(issuerConfig: responseModel)
                        credentialDisplay = createCredentialDisplay(credDisplay: credentialDisplay2 ?? nil)
                        issueHandler = IssueService(keyHandler: keyHandler)
                        let credentialResponse = await issueHandler?.processCredentialRequest(did: did, nonce: c_nonce, credentialOffer: EBSIWallet.shared.credentialOffer!, issuerConfig: responseModel, accessToken: accessToken, format: "", credentialTypes: credential.types ?? [], tokenResponse: tokenResponse, authDetails: auth, privateKey: encryptionDetails.0)
                        
                
                if credentialResponse?.error == nil {
                   
                    if credentialResponse?.acceptanceToken != nil {
                        UIApplicationUtils.hideLoader()
                        // Deffered credential
//                        Task {
                        var isValidOrganization: Bool? = nil
                        
                        isValidOrganization = await TrustMechanismManager()
                            .isIssuerOrVerifierTrustedAsync(credential: credentialResponse?.credential ?? credentialResponse?.credentials?.first?.credential, format: format, jwksURI: jwkUri) ?? false
                        
                        
                        var credentialNames: [String] = []
                        for data in EBSIWallet.shared.credentialOffer?.credentials ?? []{
                            let name = issueHandler?.getCredentialDisplayFromIssuerConfig(issuerConfig: responseModel, type: data.types?.last)?.name ?? ""
                            credentialNames.append(name)
                        }
                        
                        
                        await self.storeDefferedCredentialDetails(credentialResponse!, jwkUri: jwkUri, accessToken: accessToken, refreshToken: refreshToken, tokenEndPoint: tokenEndPoint, isValidOrganization: isValidOrganization, credentialNames: credentialNames, isPWA: isPWA, ecPrivateKey: encryptionDetails.0, issuerConfig: openIdIssuerResponseData, credentialOffer: EBSIWallet.shared.credentialOffer, credentialDisplay: credentialDisplay, jwks: responseModel.credentialRequestEncryption?.jwks?.first, encryptionRequired: responseModel.credentialRequestEncryption?.encryptionRequired)
                        NotificationCenter.default.post(name: Constants.reloadOrgList, object: nil)
                    } else {
                        // Other credential
                        //                        UIApplicationUtils.hideLoader()
//                        Task {
                            do {
                                let authServerUrl = AuthorizationServerUrlUtil().getAuthorizationServerUrl(issuerConfig: responseModel, credentialOffer: credentialOffer)
                                let authServer = EBSIWallet.shared.getAuthorizationServerFromCredentialOffer(credential: credentialOffer) ?? authServerUrl
                                let authConfig = try await DiscoveryService.shared.getAuthConfig(authorisationServerWellKnownURI: (authServer == nil ? credentialOffer?.credentialIssuer : authServer) ?? "")
                                let format = issueHandler?.getFormatFromIssuerConfig(issuerConfig: responseModel, type: credentialTypes?.last)
                                try await CredentialValidatorService.shared.validateCredential(jwt: credentialResponse?.credential, jwksURI: authConfig?.jwksURI, format: format ?? "")
                                UIApplicationUtils.hideLoader()
                                var isValidOrganization: Bool? = nil
                                isValidOrganization = await TrustMechanismManager()
                                    .isIssuerOrVerifierTrustedAsync(credential: credentialResponse?.credential ?? credentialResponse?.credentials?.first?.credential, format: format, jwksURI: jwkUri) ?? false

                                await self.addCredentialToWallet(
                                    credentialResponse: credentialResponse,
                                    ebsiV3Exchange: ebsiV3Exchange,
                                    accessToken: accessToken,
                                    refreshToken: refreshToken,
                                    notificationEndPoint: responseModel.notificationEndPoint ?? "",
                                    tokenEndPoint: tokenEndPoint,
                                    isValidOrganization: isValidOrganization,
                                    credentialType: credential.types?.last ?? "", jwksURI: jwkUri, credentialOffer: credentialOffer, issuerConfig: responseModel, credentialDisplay: credentialDisplay
                                )
                            }
                            catch ValidationError.JWTExpired {
                                UIApplicationUtils.showErrorSnackbar(message: "error_jwt_token_expired".localized())
                                UIApplicationUtils.hideLoader()
                            } catch ValidationError.signatureExpired {
                                UIApplicationUtils.showErrorSnackbar(message: "error_jwt_signature_invalid".localized())
                                UIApplicationUtils.hideLoader()
                            } catch ValidationError.invalidKID {
                                let message = "error_jwt_signature_invalid_with_type".localized()
                                UIApplicationUtils.showErrorSnackbar(message: message.replacingOccurrences(of: "<type>", with: "x5c"))
                                UIApplicationUtils.hideLoader()
                            }
                    }
                } else {
                    UIApplicationUtils.showErrorSnackbar(message: credentialResponse?.error?.message ?? "Internal Server Error")
                    UIApplicationUtils.hideLoader()
                }
                
            }
        }
            }
        } catch {
            UIApplicationUtils.hideLoader()
            debugPrint("JSON Serialization error")
        }
    }
    
    fileprivate func storeDefferedCredentialDetails(_ credentialResponse: CredentialResponse, jwkUri: String?, accessToken: String?, refreshToken: String?, tokenEndPoint: String?, isValidOrganization: Bool?, credentialNames: [String] = [], isPWA: Bool? = false, ecPrivateKey: ECPrivateKey?, issuerConfig: IssuerWellKnownConfiguration?, credentialOffer: CredentialOffer?, credentialDisplay: Display?, jwks: JWKData?, encryptionRequired: Bool?) async {
        let pollingHelper = DeferredCredentialPollingHelper.shared
//        Task {
            
            // to save deferred credential details
            var connectionModel = CloudAgentConnectionWalletModel()
            if EBSIWallet.shared.version == .v3 || EBSIWallet.shared.version == .v2 {
                connectionModel = await getEBSI_V3_connection() ?? CloudAgentConnectionWalletModel()
            } else if  EBSIWallet.shared.version == .dynamic {
                if let responseModel = issuerConfig {
                    connectionModel = await getEBSI_V3_connection(orgID: credentialIssuer) ?? CloudAgentConnectionWalletModel()
                }
            }
            connectionModel.value?.orgDetails?.isValidOrganization = isValidOrganization
            connectionModel.value?.orgDetails?.x5c = credentialResponse.credential ?? credentialResponse.credentials?.first?.credential ?? ""
            connectionModel.value?.orgDetails?.jwksURL = jwkUri
        let deferredCacheModel = DeferredCacheModel(acceptanceToken: credentialResponse.acceptanceToken, deferredEndPoint: issuerConfig?.deferredCredentialEndpoint, jwkUris: jwkUri, credentialDisplay: credentialDisplay, connectionDetails: connectionModel,accessToken: accessToken, version: credentialOffer?.version, refreshToken: refreshToken, notificationID: credentialResponse.notificationID, notificationEndPont: issuerConfig?.notificationEndPoint, tokenEndPoint: tokenEndPoint, ecPrivateKey: ecPrivateKey, jwks: jwks, encryptionRequired: encryptionRequired)
            
            // to update the credential
            pollingHelper.updateDeferredCredentialRequestCacheList(deferredCacheModel)
        if dynamicCredentialCount == credentialOffer?.credentials?.count {
            if isDynamicCredentialRequest {
                let messageText = generateCredentialMessage(credentialNames: credentialNames, isPWA: isPWA)
                UIApplicationUtils.hideLoader()
                DispatchQueue.main.async {
                    UIApplicationUtils.showSuccessSnackbar(message: messageText.localized())
                }
            } else {
                showAlertForDefferedType()
            }
        }
        await self.defferedCredentialRequest(deferredCacheModel: deferredCacheModel, issuerConfig: issuerConfig, credentialOffer: credentialOffer)
//        }
    }
    
    func showAlertForDefferedType() {
        UIApplicationUtils.hideLoader()
        DispatchQueue.main.async {
            UIApplicationUtils.showSuccessSnackbar(message: "A request has been sent to the issuer. You will be notified once your request is processed.".localized())
        }
    }
    
    func defferedCredentialRequest(deferredCacheModel: DeferredCacheModel?, issuerConfig: IssuerWellKnownConfiguration?, credentialOffer: CredentialOffer?) async {
        let pollingHelper = DeferredCredentialPollingHelper.shared

        // add version in DeferredCacheModel and use thar version
        debugPrint("started deferred polling for \(deferredCacheModel?.acceptanceToken)")
        guard let defferedToken = deferredCacheModel?.acceptanceToken else { return }
        guard let endpoints = deferredCacheModel?.deferredEndPoint else { return }
        Task{
            let credentialResponse = await issueHandler?.processDeferredCredentialRequest(acceptanceToken: defferedToken, deferredCredentialEndPoint:endpoints, version: deferredCacheModel?.version, accessToken: deferredCacheModel?.accessToken, privateKey: deferredCacheModel?.ecPrivateKey, jwks: deferredCacheModel?.jwks?.dictionary, encryptionRequired: deferredCacheModel?.encryptionRequired)
            if (credentialResponse?.credential) != nil || credentialResponse?.credentials?.isNotEmpty == true {
                        do {
                            let credentialTypes = issueHandler?.getTypesFromCredentialOffer(credentialOffer: credentialOffer)
                            let format = issueHandler?.getFormatFromIssuerConfig(issuerConfig: issuerConfig, type: credentialTypes?.last)
                            try await CredentialValidatorService.shared.validateCredential(jwt: credentialResponse?.credential ?? credentialResponse?.credentials?.first?.credential, jwksURI: deferredCacheModel?.jwkUris, format: format ?? "")
//                            let isSameDID = await DIDComapare (credentialResponse: credentialResponse)
//                            if isSameDID {
                            var isValidOrganization = await TrustMechanismManager()
                                .isIssuerOrVerifierTrustedAsync(credential: credentialResponse?.credential ?? credentialResponse?.credentials?.first?.credential, format: format, jwksURI: deferredCacheModel?.jwkUris) ?? false
                            await self.addCredentialToWallet(credentialResponse: credentialResponse, isDeferred: true, connectionModel: deferredCacheModel?.connectionDetails, deferredCacheModel: deferredCacheModel, isValidOrganization: isValidOrganization, jwksURI: deferredCacheModel?.jwkUris, credentialOffer: credentialOffer, issuerConfig: issuerConfig, credentialDisplay: deferredCacheModel?.credentialDisplay)
//                            }
                            // TODO: verify credential removal
                            pollingHelper.removeDeferredCredentialRequestCacheList(acceptanceToken: defferedToken)
                        }
                        catch ValidationError.JWTExpired{
                            UIApplicationUtils.showErrorSnackbar(message: "error_jwt_token_expired".localized())
                        } catch ValidationError.signatureExpired {
                            UIApplicationUtils.showErrorSnackbar(message: "error_jwt_signature_invalid".localized())
                        } catch ValidationError.invalidKID {
                            let message = "error_jwt_signature_invalid_with_type".localized()
                            UIApplicationUtils.showErrorSnackbar(message: message.replacingOccurrences(of: "<type>", with: "x5c"))
                            UIApplicationUtils.hideLoader()
                        }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        Task{
                            await self.defferedCredentialRequest(deferredCacheModel: deferredCacheModel, issuerConfig: issuerConfig, credentialOffer: credentialOffer)
                        }
                }
            }
        }
    }
    
    
    func generateCredentialMessage(credentialNames: [String?], isPWA: Bool?) -> String {
            let availableNames = credentialNames.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            let totalCount = credentialNames.count
            let namedCount = availableNames.count
        let conformText = isPWA ?? false ? ("pwa_payment_confirmed".localizedForSDK().capitalized + "!"): "verification_successfull".localizedForSDK()
            switch totalCount {
            case 1:
                if namedCount == 1 {
                    return String(format: "credential_issuance_single_named".localizedForSDK(), conformText, availableNames[0])
                } else {
                    return "\(conformText) A credential will be issued shortly."
                }

            default:
                if namedCount == totalCount {
                    
                    let formatter = ListFormatter()
                    if let formattedList = formatter.string(from: availableNames) {
                        return String(format: "credential_issuance_multiple_all_named_ios".localizedForSDK(), conformText, formattedList)
                    }
                } else if namedCount > 0 {
                    let othersCount = totalCount - 1
                    let plural = othersCount == 1 ? "credential".localizedForSDK() : "credentials".localizedForSDK()
                    return String(
                        format: "credential_issuance_multiple_partial_named_ios".localizedForSDK(),
                        conformText,
                        availableNames[0],
                        othersCount,
                        plural
                    )
                } else {
                    return String(format: "credential_issuance_multiple_none_named_ios".localizedForSDK(), conformText)
                }
            }

        return String(format: "credential_issuance_multiple_none_named_ios".localizedForSDK(), conformText)
        }
   // @available(iOS 14.0, *)
    public func handleAuthorizationResponse(authorisationResponeData: String?,authorisationResponeError: eudiWalletOidcIos.EUDIError?, codeVerifier: String, tokenEndpoint: String, authServerUrl: String, jwkUri: String?, privateKey: P256.Signing.PrivateKey, credentialOffer: CredentialOffer?, issuerConfig: IssuerWellKnownConfiguration?) {
        if authorisationResponeData?.isNotEmpty == true {
            guard let url = URL(string: authorisationResponeData ?? "") else { return }
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            
            if let error = components?.queryItems?.first(where: { $0.name == "error" })?.value {
                guard let errorDescription = components?.queryItems?.first(where: { $0.name == "error_description" })?.value else {
                    DispatchQueue.main.async {
                        UIApplicationUtils.showErrorSnackbar(message: "connection_unexpected_error_please_try_again".localized())
                        UIApplicationUtils.hideLoader()
                    }
                    return
                }
                DispatchQueue.main.async {
                    UIApplicationUtils.showErrorSnackbar(message: errorDescription)
                    UIApplicationUtils.hideLoader()
                }
            } else if let url = URL(string: url.absoluteString), let redirectUri = url.queryParameters?["redirect_uri"] , let responseType = url.queryParameters?["response_type"], responseType == "id_token" {
                
                Task {
                    let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyHandlerKeyID)
                    let issueHandler = IssueService(keyHandler: keyHandler)
                    let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
                    let nonce = url.queryParameters?["nonce"]
                    let state = url.queryParameters?["state"]
                    let clientID = url.queryParameters?["client_id"]
                    let uri = redirectUri.replacingOccurrences(of: "\n", with: "")
                    guard let auth = EBSIWallet.shared.authConfigData else { return }
                    let code =  await issueHandler.processAuthorisationRequestUsingIdToken(
                        did: did,
                        authServerWellKnownConfig: auth,
                        redirectURI:  uri.trimmingCharacters(in: .whitespaces) ,
                        nonce: nonce ?? "",
                        state: state ?? "", clientID: clientID ?? "")
                    EBSIWallet.shared.handleAuthorizationResponse(authorisationResponeData: code, authorisationResponeError: nil, codeVerifier: codeVerifier, tokenEndpoint: auth.tokenEndpoint ?? "", authServerUrl: authServerUrl, jwkUri: auth.jwksURI, privateKey: EBSIWallet.shared.handlePrivateKey(), credentialOffer: credentialOffer, issuerConfig: issuerConfig)
                }
                
            } else if (components?.queryItems?.contains(where: {
                ["presentation_definition", "request_uri", "presentation_definition_uri"].contains($0.name)
            }) == true) || ( components?.queryItems?.first(where: { $0.name == "type" })?.value == "openid4vp_presentation") {
                Task{
                    let presentationRequestData = await verificationHandler?.processAuthorisationRequest(data: url.absoluteString)
                     presentationRequestJwt = presentationRequestData?.0?.request ?? ""
                    self.presentationDefinition = presentationRequestData?.0?.presentationDefinition ?? ""
                    self.dcqlQuery = presentationRequestData?.0?.dcqlQuery
                    if presentationRequestData?.1 != nil {
                        UIApplicationUtils.hideLoader()
                        UIApplicationUtils.showErrorSnackbar(message: presentationRequestData?.1?.message ?? "")
                    } else {
                        let presentationRequest = presentationRequestData?.0
                        let urlString = "openid4vp://?client_id=\(presentationRequest?.clientId ?? "")&response_type=\(presentationRequest?.responseType ?? "")&scope=\(presentationRequest?.scope ?? "")&redirect_uri=\(presentationRequest?.redirectUri ?? presentationRequest?.responseUri ?? "")&request_uri=\(presentationRequest?.requestUri ?? "")&response_mode=\(presentationRequest?.responseMode ?? "")&state=\(presentationRequest?.state ?? "")&nonce=\(presentationRequest?.nonce ?? "")&auth_session=\(presentationRequest?.authSession ?? "")"
                        let clientID = presentationRequest?.clientId ?? ""
                        var newOrgID: String = ""
                        if let isDraft = DraftSuffixProcessor().isDraftID(clientID), isDraft {
                            newOrgID = DraftSuffixProcessor().removeDraftSuffix(from: clientID) ?? ""
                        } else {
                            newOrgID = clientID
                        }
                        EBSIWallet.shared.exchangeClientID = clientID
                        self.isDynamicCredentialRequest = true
                        await EBSIWallet.shared.processVerifiablePresentationExchange(uri: urlString, presentationDefinition: presentationRequest?.presentationDefinition ?? "", clientMetaData: presentationRequest?.clientMetaData ?? "", transactionData: presentationRequest?.transactionData ?? [], authSession: presentationRequest?.authSession)
                    }
                }
            } else {
                let walletHandler = WalletViewModel.openedWalletHandler ?? 0
                AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation,searchType: .withoutQuery) { (success, searchHandler, error) in
                    AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [self] (fetched, response, error) in
                    let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                    let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                    guard let code = components?.queryItems?.first(where: {$0.name == "code"})?.value else  { return }
                    Task {
                        let keyHandler = SecureEnclaveHandler(keyID: self.keyHandlerKeyID)
                        let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
                        let pop = await WalletUnitAttestationService().generateWUAProofOfPossession(keyHandler: keyHandler, aud: credentialOffer?.credentialIssuer)
                        let clientIDAssertion = await WalletUnitAttestationService().createClientAssertion(aud: credentialOffer?.credentialIssuer ?? "", keyHandler: keyHandler)
                        let accessTokenResponse = await self.issueHandler?.processTokenRequest(did: did, tokenEndPoint: tokenEndpoint, code: code, codeVerifier: codeVerifier, isPreAuthorisedCodeFlow: false, userPin: "", version: "", clientIdAssertion: clientIDAssertion, wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT ?? "", pop: pop, redirectURI: webRedirectURI)
                        if accessTokenResponse?.error != nil{
                            DispatchQueue.main.async {
                                UIApplicationUtils.hideLoader()
                                UIApplicationUtils.showErrorSnackbar(message: accessTokenResponse?.error?.message ?? "connection_unexpected_error_please_try_again".localized())
                            }
                        } else {
                            let nonce = await NonceServiceUtil().fetchNonce(accessTokenResponse: accessTokenResponse, nonceEndPoint: issuerConfig?.nonceEndPoint)
                            await self.requestCredentialUsingEbsiV3(didKeyIdentifier: globalDID, c_nonce: nonce ?? "", accessToken: accessTokenResponse?.accessToken ?? "", privateKey: privateKey, authServerURL: authServerUrl, jwkUri: jwkUri, refreshToken: accessTokenResponse?.refreshToken ?? "", tokenEndPoint: tokenEndpoint, authDetails: accessTokenResponse?.authorizationDetails, tokenResponse: accessTokenResponse, credentialOffer: credentialOffer, issuerConfig: issuerConfig)
                        }
                    }
                }
            }
            }
        } else if authorisationResponeData?.isEmpty == true {
            UIApplicationUtils.hideLoader()
            UIApplicationUtils.showErrorSnackbar(message: authorisationResponeError?.message ?? "Authentication failed".localized())
        } else if authorisationResponeError != nil {
            UIApplicationUtils.hideLoader()
            UIApplicationUtils.showErrorSnackbar(message: authorisationResponeError?.message ?? "")
        }
    }
    
    func createDIDKeyIdentifierForV3(privateKey: P256.Signing.PrivateKey, orgDisplayName: String? = "") -> String? {
        let did =  createDIDKeyIdentifierForDynamicOrg(privateKey: privateKey)
        debugPrint("[DEBUG] Inside createDIDKeyIdentifierForV3(): Create did:key identifier in real-time from the private key")
        return did
    }
    
    func EBSI_V3_store_dynamic_organisation_details(responseData: IssuerWellKnownConfiguration?, isVerification: Bool = false, transactionData: TransactionData? = nil, credentialOffer: CredentialOffer?, completion: @escaping (Bool) -> ()) {
        do {
            let jsonDecoder = JSONDecoder()
            let privateKey =  handlePrivateKey()
            
                Task {
                    let responseModel = responseData
                    var orgDetail = OrganisationInfoModel.init()
                    var imageURL = ""
                    let clientDataString = clientMetaData.replacingOccurrences(of: "+", with: " ")
                    let clientMetadataJson = clientDataString.replacingOccurrences(of: "\'", with: "\"").data(using: .utf8)!
                    let clientMetaDataModel = try? JSONDecoder().decode(ClientMetaData.self, from: clientMetadataJson)

                    if isVerification {
                            imageURL =  clientMetaDataModel?.coverUri ?? ""
                            orgDetail.orgId = exchangeClientID
                            orgDetail.logoImageURL = clientMetaDataModel?.logoUri ?? "https://storage.googleapis.com/data4diabetes/unknown.png"
                            orgDetail.coverImageURL = clientMetaDataModel?.coverUri ?? ""
                            orgDetail.location = clientMetaDataModel?.location ?? "Not Discoverable"
                            orgDetail.organisationInfoModelDescription = clientMetaDataModel?.description ?? ""
                            orgDetail.name = clientMetaDataModel?.clientName ?? "Unknown Org"
                        let did = await EBSIWallet.shared.createDIDKeyIdentifierForDynamicOrg(privateKey: privateKey) ?? ""
                        let (_, connID) = try await WalletRecord.shared.add(invitationKey: "", label: clientMetaDataModel?.clientName ?? "Unknown Org", serviceEndPoint: "", connectionRecordId: "",imageURL: imageURL , walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),type: .connection, orgID: orgDetail.orgId)

                        let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),recipientKey: "",label: clientMetaDataModel?.clientName ?? "Unknown Org", type: UpdateWalletType.trusted, id: connID, theirDid: "", myDid: did,imageURL: imageURL ,invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: orgDetail, orgID: orgDetail.orgId)
                        _ = try await
                        AriesAgentFunctions.shared.updateWalletTags(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), id: connID, myDid: did, type: .cloudAgentActive, orgID: orgId)
                    } else {
                        var display = getDisplayFromIssuerConfig(config: responseModel)
                        if display == nil {
                            display =  Display(mName: "Unknown Org", mLocation: "Not Discoverable", mLocale: "en", mDescription: "", mCover: DisplayCover(mUrl: nil, mAltText: nil), mLogo: DisplayCover(mUrl: "https://storage.googleapis.com/data4diabetes/unknown.png", mAltText: nil), mBackgroundColor: nil, mTextColor: nil)
                        }
                        let imageURL =  display?.cover?.url ?? ""
                        orgDetail.orgId = credentialIssuer
                        orgDetail.logoImageURL = display?.logo?.url ?? display?.logo?.uri
                        orgDetail.coverImageURL = display?.cover?.url
                        orgDetail.location = display?.location
                        orgDetail.organisationInfoModelDescription = display?.description
                        orgDetail.name = display?.name
                        
                        let did = await EBSIWallet.shared.createDIDKeyIdentifierForDynamicOrg(privateKey: privateKey) ?? ""
                        let (_, connID) = try await WalletRecord.shared.add(invitationKey: "", label: display?.name ?? "", serviceEndPoint: "", connectionRecordId: "",imageURL: imageURL, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),type: .connection, orgID: orgDetail.orgId)
                        
                        let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),recipientKey: "",label: display?.name ?? "", type: UpdateWalletType.trusted, id: connID, theirDid: "", myDid: did,imageURL: imageURL,invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: orgDetail, orgID: orgDetail.orgId)
                        _ = try await
                        AriesAgentFunctions.shared.updateWalletTags(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), id: connID, myDid: did, type: .cloudAgentActive, orgID: orgId)
                    }
                    var display: Display? = nil
                    if isVerification {
                        display = convertClientMetaDataToDisplay(clientMetaData: clientMetaDataModel)
                    } else {
                        display = getDisplayFromIssuerConfig(config: responseData)
                    }
                    guard display?.name != "Unknown Org" else {
                        DispatchQueue.main.async {
                            completion(true)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        completion(true)
                    }
//                    let connectionName = isVerification ? "EBSI_" + (clientMetaDataModel?.clientName ?? "") : "EBSI_" + (display?.name ?? "")
//                    let issuerOrVerifierId = isVerification ? exchangeClientID : credentialIssuer
//                    MigrationHandler.shared.performMigration(connectionName: connectionName, issuerOrVerifierId: issuerOrVerifierId, orgId: orgId) { success in
//                        DispatchQueue.main.async {
//                            completion(true)
//                        }
//                    }
                }
        } catch {
            UIApplicationUtils.hideLoader()
            debugPrint("Error:\(error.localizedDescription)")
            completion(false)
        }
    }

    func createDIDKeyIdentifierForDynamicOrg(privateKey: P256.Signing.PrivateKey) -> String? {
        // Step 1: Create P-256 public and private key pair
        let publicKey = privateKey.publicKey
        
        // Step 2: Export public key JWK
        let rawRepresentation = publicKey.rawRepresentation
        let x = rawRepresentation[rawRepresentation.startIndex..<rawRepresentation.index(rawRepresentation.startIndex, offsetBy: 32)]
        let y = rawRepresentation[rawRepresentation.index(rawRepresentation.startIndex, offsetBy: 32)..<rawRepresentation.endIndex]
        let jwk: [String: Any] = [
            "crv": "P-256",
            "kty": "EC",
            "x": x.urlSafeBase64EncodedString(),
            "y": y.urlSafeBase64EncodedString()
        ]
        
        do {
            // Step 3: Convert JWK to JSON string
            let jsonData = try JSONSerialization.data(withJSONObject: jwk, options: [.sortedKeys])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                return nil
            }
            
            // Step 4: Remove whitespaces from the JSON string
            let compactJsonString = jsonString.replacingOccurrences(of: " ", with: "")
            
            // Step 5: UTF-8 encode the string
            guard let encodedData = compactJsonString.data(using: .utf8) else {
                return nil
            }
            
            // Step 6: Add multicodec byte for jwk_jcs-pub
            let multicodecByte: [UInt8] = [209, 214, 3]
            var multicodecData = Data(fromArray: multicodecByte)
            multicodecData.append(encodedData)
            
            // Step 7: Apply multibase base58-btc encoding
            let multibaseEncodedString =  Base58.base58Encode([UInt8](multicodecData))
            
            // Step 8: Prefix the string with did:key:z
            let didKeyIdentifier = "did:key:z" + multibaseEncodedString
            
            return didKeyIdentifier
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
    
    func hexStringOfRandom6Bytes() -> String{
        let data = try? Data.random(length: 6)
        let hex = data?.toHexString() ?? ""
        return hex
    }
    
    func addCredentialToWallet(credentialResponse: CredentialResponse? = nil, ebsiV3Exchange: Bool = false, isDeferred: Bool = false, connectionModel: CloudAgentConnectionWalletModel? = nil, deferredCacheModel: DeferredCacheModel? = nil, credentialCBOR: String = "", accessToken: String = "", refreshToken: String = "", notificationEndPoint: String = "", tokenEndPoint: String = "", isValidOrganization: Bool? = false,credentialType: String = "", jwksURI: String?, credentialOffer: CredentialOffer?, issuerConfig: IssuerWellKnownConfiguration?, credentialDisplay: Display?, completion: @escaping (Bool) -> Void = { _ in }) async {
                var connection = connectionModel
                let format = issueHandler?.getFormatFromIssuerConfig(issuerConfig: issuerConfig, type: credentialType)
                print("formate is : \(format)")
                if connection == nil {
                    print("ebsi bevrr: \(EBSIWallet.shared.version)")
                    if EBSIWallet.shared.version == .v3 || EBSIWallet.shared.version == .v2 {
                        connection = await getEBSI_V3_connection() ?? CloudAgentConnectionWalletModel()
                    } else if  EBSIWallet.shared.version == .dynamic {
                        if let responseModel = issuerConfig {
                            connection = await getEBSI_V3_connection(orgID: credentialIssuer) ?? CloudAgentConnectionWalletModel()
                        }
                    }
                }
                connection?.value?.orgDetails?.isValidOrganization = isValidOrganization
                connection?.value?.orgDetails?.x5c = credentialResponse?.credential ?? credentialResponse?.credentials?.first?.credential ?? ""
                connection?.value?.orgDetails?.jwksURL = jwksURI
                var credentialData = credentialResponse?.credential ?? credentialResponse?.credentials?.first?.credential ?? ""
                let credentialCount = credentialData.split(separator: ".")
        if format == "mso_mdoc" || credentialCount.count == 1 {
                    let customWalletModel = CustomWalletRecordCertModel.init()
            MDOCParser.shared.createMDOCCredential(customWalletModel: customWalletModel, connectionModel: connection ?? CloudAgentConnectionWalletModel(), credential_cbor: credentialResponse?.credential ?? credentialResponse?.credentials?.first?.credential ?? "", format: format ?? "", accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: credentialResponse?.notificationID ?? "", tokenEndPoint: tokenEndPoint)
                    do {
                        if (isDeferred) {
                            // setting credential branding data
                            let searchText = customWalletModel.searchableText
                            customWalletModel.searchableText = deferredCacheModel?.credentialDisplay?.name?.camelCaseToWords().uppercased() ?? searchText
                            customWalletModel.description = deferredCacheModel?.credentialDisplay?.description
                            customWalletModel.logo = deferredCacheModel?.credentialDisplay?.logo?.uri
                            customWalletModel.cover = deferredCacheModel?.credentialDisplay?.bgImage?.uri
                            customWalletModel.backgroundColor = deferredCacheModel?.credentialDisplay?.backgroundColor
                            customWalletModel.textColor = deferredCacheModel?.credentialDisplay?.textColor
                            customWalletModel.accessToken = deferredCacheModel?.accessToken
                            customWalletModel.refreshToken = deferredCacheModel?.refreshToken
                            customWalletModel.notificationID = credentialResponse?.notificationID
                            customWalletModel.notificationEndPont = deferredCacheModel?.notificationEndPont
                            customWalletModel.tokenEndPoint = deferredCacheModel?.tokenEndPoint
                            UIApplicationUtils.hideLoader()
                            let (_, _) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, connectionModel: connection ?? CloudAgentConnectionWalletModel(), walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .inbox_EBSIOffer)
                            NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
                            UIApplicationUtils.showSuccessSnackbar(message: "data_received_offer_credentials".localizedForSDK(),navToNotifScreen:true)
                            return
                        } else if (ebsiV3Exchange == true ) {
                            UIApplicationUtils.hideLoader()
                            let (_, _) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, connectionModel: connection ?? CloudAgentConnectionWalletModel(), walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .generic)
                            NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
                            //await addEBSIExchangeCertToHistory(connectionModel: connection ?? CloudAgentConnectionWalletModel())
                            return
                        }
                        else {
                            // Note: If it is not from 'Deffered credential' flow or not from 'EBSI_V3 certificate exchange' flow, navigate to certificate preview screen
                            UIApplicationUtils.hideLoader()
                            let accepted = await withCheckedContinuation { continuation in
                                                showCertificatePreview2(
                                                    customWalletModel,
                                                    connection ?? CloudAgentConnectionWalletModel(),
                                                    isValidOrganization: isValidOrganization, credentailDisplay: credentialDisplay
                                                ) { accept in
                                                    continuation.resume(returning: accept)
                                                }
                                            }
                        }
                        let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),recipientKey: "",label: connection?.value?.orgDetails?.name ?? "", type: UpdateWalletType.trusted, id: connection?.value?.requestID ?? "", theirDid: "", myDid: connection?.value?.myDid ?? "",imageURL: connection?.value?.orgDetails?.coverImageURL ?? "" ,invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: connection?.value?.orgDetails, orgID: connection?.value?.orgDetails?.orgId)
                    } catch {
                        UIApplicationUtils.hideLoader()
                        debugPrint(error.localizedDescription)
                        return
                    }
                } else {
                    let credential_jwt = credentialResponse?.credential ?? credentialResponse?.credentials?.first?.credential ?? ""
                    let credential_jwt_parts = credential_jwt.split(separator: ".")
                    let credential_jwt_payload = "\(credential_jwt_parts[safe: 1] ?? "")"
                    let credential = credential_jwt_payload.decodeBase64() ?? ""
                    let tempCredential = SDJWTUtils.shared.updateIssuerJwtWithDisclosures(credential: credential_jwt)
                    let dict = UIApplicationUtils.shared.convertToDictionary(text: tempCredential ?? "{}") ?? [:]
                    
                    // For Model 1
                    if let credentialModel = EBSI_V2_VerifiableID.decode(withDictionary: dict as [String : Any]) as? EBSI_V2_VerifiableID {
                        let customWalletModel = CustomWalletRecordCertModel.init()
                        
                        if credentialModel.vc?.type?.contains("eu.europa.ec.eudi.photoid.1") == true {
                            PhotoIDParser.shared.createPhotoID(dict: dict as [String : Any], customWalletModel: customWalletModel, credential_jwt: credential_jwt, credentialModel: credentialModel, format: format ?? "", connectionModel: connection ?? CloudAgentConnectionWalletModel(), accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: credentialResponse?.notificationID ?? "", tokenEndPoint: tokenEndPoint, photoID: credentialModel.vc?.credentialSubject?.photoid, iso: credentialModel.vc?.credentialSubject?.iso23220)
                        } else if let data = credentialModel.vc?.credentialSubject?.achieved?.first {
                            createDiplomaCertificate(data, customWalletModel, connection ?? CloudAgentConnectionWalletModel(), credentialModel, credential_jwt, accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: credentialResponse?.notificationID ?? "", tokenEndPoint: tokenEndPoint)
                        } else if let data = credentialModel.vc?.credentialSubject?.identifier?.first {
                            createStudentId(data, credentialModel, customWalletModel, connection ?? CloudAgentConnectionWalletModel(), credential_jwt, accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: credentialResponse?.notificationID ?? "", tokenEndPoint: tokenEndPoint)
                        }
                        else if ((credentialModel.vc?.type?.contains("VerifiablePortableDocumentA1")) == true) || ((credentialModel.vc?.type?.contains("PortableDocumentA1")) == true)  {
                            let section1 = credentialModel.vc?.credentialSubject?.section1
                            let section2 = credentialModel.vc?.credentialSubject?.section2
                            let section3 = credentialModel.vc?.credentialSubject?.section3
                            let section4 = credentialModel.vc?.credentialSubject?.section4
                            let section5 = credentialModel.vc?.credentialSubject?.section5
                            let section6 = credentialModel.vc?.credentialSubject?.section6
                            OpenIdPDA1Parser.shared.createPDA(section1, section2, section3, section4, section5, section6, customWalletModel, connection ?? CloudAgentConnectionWalletModel(), credentialModel: credentialModel, credential_jwt, format: format ?? "",accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: credentialResponse?.notificationID ?? "", tokenEndPoint: tokenEndPoint)
                        } else if let vct = credentialModel.vct,
                                  vct == "PaymentWalletAttestation" {
                            
                            if credentialModel.fundingSource != nil {
                                let credentialType = EBSIWallet.shared.fetchCredentialType(list: credentialModel.vc?.type)
                                customWalletModel.referent = nil
                                customWalletModel.schemaID = nil
                                customWalletModel.certInfo = nil
                                customWalletModel.connectionInfo = connection
                                customWalletModel.type = CertType.EBSI.rawValue
                                customWalletModel.subType = EBSI_CredentialType.PWA.rawValue
                                customWalletModel.searchableText = credentialType?.camelCaseToWords().uppercased() ??  EBSI_CredentialSearchText.PDA1.rawValue.uppercased()
                                customWalletModel.format = format
                                customWalletModel.vct = credentialModel.vct
                                customWalletModel.fundingSource = credentialModel.fundingSource
                                customWalletModel.accessToken = accessToken
                                customWalletModel.refreshToken = refreshToken
                                customWalletModel.notificationID = credentialResponse?.notificationID
                                customWalletModel.notificationEndPont = notificationEndPoint
                                customWalletModel.tokenEndPoint = tokenEndPoint
                                customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: [], issuer: credentialModel.iss, credentialJWT: credential_jwt)
                            } else {
                                OpenIdPWACredentialParser.shared.createPWACredential( customWalletModel, connection ?? CloudAgentConnectionWalletModel(), credentialModel, credential_jwt, format: format ?? "", accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: credentialResponse?.notificationID ?? "", tokenEndPoint: tokenEndPoint)
                            }
                        } else {
                            var subjectDict = [String: Any]()
                            if let vc = dict["vc"] as? [String: Any],
                               let credentialSubject = vc["credentialSubject"] as? [String: Any]{
                                let keys = credentialSubject.compactMap({ $0.key })
                                let values = credentialSubject.compactMap({ $0.value })
                                
                                for i in 0..<keys.count {
                                    subjectDict[keys[i]] = values[i]
                                }
                            } else {
                                let keys = dict.compactMap({ $0.key})
                                let values = dict.compactMap({ $0.value })
                                
                                for i in 0..<keys.count {
                                    if keys[i] != "iss" && keys[i] != "iat" && keys[i] != "vct" && keys[i] != "_sd" && keys[i] != "_sd_alg" && keys[i] != "jti" &&  keys[i] != "cnf" &&  keys[i] != "sub" &&  keys[i] != "nbf" &&  keys[i] != "exp" && keys[i] != "status" {
                                        subjectDict[keys[i]] = values[i]
                                    }
                                }
                            }
                            createFallbackCredential(subjectDict, credentialModel, customWalletModel, connection ?? CloudAgentConnectionWalletModel(), credential_jwt: credential_jwt, format: format ?? "", accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: credentialResponse?.notificationID ?? "", tokenEndPoint: tokenEndPoint, credentialType: credentialType)
                        }
                        
                        do {
                            if (isDeferred) {
                                // setting credential branding data
                                let searchText = customWalletModel.searchableText
                                customWalletModel.searchableText = deferredCacheModel?.credentialDisplay?.name?.camelCaseToWords().uppercased() ?? searchText
                                customWalletModel.description = deferredCacheModel?.credentialDisplay?.description
                                customWalletModel.logo = deferredCacheModel?.credentialDisplay?.logo?.uri
                                customWalletModel.cover = deferredCacheModel?.credentialDisplay?.bgImage?.uri
                                customWalletModel.backgroundColor = deferredCacheModel?.credentialDisplay?.backgroundColor
                                customWalletModel.textColor = deferredCacheModel?.credentialDisplay?.textColor
                                customWalletModel.accessToken = deferredCacheModel?.accessToken
                                customWalletModel.refreshToken = deferredCacheModel?.refreshToken
                                customWalletModel.notificationID = credentialResponse?.notificationID
                                customWalletModel.notificationEndPont = deferredCacheModel?.notificationEndPont
                                customWalletModel.tokenEndPoint = deferredCacheModel?.tokenEndPoint
                                UIApplicationUtils.hideLoader()
                                let (_, _) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, connectionModel: connection ?? CloudAgentConnectionWalletModel(), walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .inbox_EBSIOffer)
                                NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
                                UIApplicationUtils.showSuccessSnackbar(message: "data_received_offer_credentials".localizedForSDK(),navToNotifScreen:true)
                                return
                            } else if (ebsiV3Exchange == true ) {
                                UIApplicationUtils.hideLoader()
                                let (_, _) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, connectionModel: connection ?? CloudAgentConnectionWalletModel(), walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .generic)
                                NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
                                //await addEBSIExchangeCertToHistory(connectionModel: connection ?? CloudAgentConnectionWalletModel())
                                return
                            } else if credentialModel.vct == "WalletUnitAttestation" {
                                UIApplicationUtils.hideLoader()
                                let (_, _) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, connectionModel: connection ?? CloudAgentConnectionWalletModel(), walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .walletUnitAttestation)
                                Task {
                                    if let notificationEndPont = customWalletModel.notificationEndPont, let notificationID = customWalletModel.notificationID {
                                        let accessTokenParts = customWalletModel.accessToken?.split(separator: ".")
                                        var accessTokenData: String? =  nil
                                        var refreshTokenData: String? =  nil
                                        if accessTokenParts?.count ?? 0 > 1 {
                                            let accessTokenBody = "\(accessTokenParts?[1] ?? "")".decodeBase64()
                                            let dict = UIApplicationUtils.shared.convertToDictionary(text: String(accessTokenBody ?? "{}")) ?? [:]
                                            let exp = dict["exp"] as? Int ?? 0
                                            let expiryDate = TimeInterval(exp)
                                            let currentTimestamp = Date().timeIntervalSince1970
                                            if expiryDate < currentTimestamp {
                                                accessTokenData = await NotificationService().refreshAccessToken(refreshToken: customWalletModel.refreshToken ?? "", endPoint: customWalletModel.tokenEndPoint ?? "").0
                                                refreshTokenData = await NotificationService().refreshAccessToken(refreshToken: customWalletModel.refreshToken ?? "", endPoint: customWalletModel.tokenEndPoint ?? "").1
                                            } else {
                                                accessTokenData = customWalletModel.accessToken
                                                refreshTokenData = customWalletModel.refreshToken
                                            }
                                        }
                                        customWalletModel.refreshToken = refreshTokenData
                                        customWalletModel.accessToken = accessTokenData
                                        await NotificationService().sendNoticationStatus(endPoint: customWalletModel.notificationEndPont, event: NotificationStatus.credentialAccepted.rawValue, notificationID: customWalletModel.notificationID, accessToken: customWalletModel.accessToken ?? "", refreshToken: customWalletModel.refreshToken ?? "", tokenEndPoint: customWalletModel.tokenEndPoint ?? "")
                                    }
                                }
                                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                            } else if EBSIWallet.shared.isFromPushNotification {
                                UIApplicationUtils.hideLoader()
                                let searchText = credentialDisplay?.name?.camelCaseToWords().uppercased()
                                let searchableText = customWalletModel.searchableText
                                if searchText != nil {
                                    customWalletModel.searchableText = searchText?.uppercased()
                                } else {
                                    customWalletModel.searchableText = searchableText
                                }
                                customWalletModel.description = credentialDisplay?.description
                                customWalletModel.logo = credentialDisplay?.logo?.uri ?? credentialDisplay?.logo?.url
                                customWalletModel.cover = credentialDisplay?.bgImage?.uri ?? credentialDisplay?.bgImage?.url
                                customWalletModel.backgroundColor = credentialDisplay?.backgroundColor
                                customWalletModel.textColor = credentialDisplay?.textColor
                                let (_, _) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, connectionModel: connection ?? CloudAgentConnectionWalletModel(), walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .walletCert)
                                Task {
                                    if let notificationEndPont = customWalletModel.notificationEndPont, let notificationID = customWalletModel.notificationID {
                                        let accessTokenParts = customWalletModel.accessToken?.split(separator: ".")
                                        var accessTokenData: String? =  nil
                                        var refreshTokenData: String? =  nil
                                        if accessTokenParts?.count ?? 0 > 1 {
                                            let accessTokenBody = "\(accessTokenParts?[1] ?? "")".decodeBase64()
                                            let dict = UIApplicationUtils.shared.convertToDictionary(text: String(accessTokenBody ?? "{}")) ?? [:]
                                            let exp = dict["exp"] as? Int ?? 0
                                            let expiryDate = TimeInterval(exp)
                                            let currentTimestamp = Date().timeIntervalSince1970
                                            if expiryDate < currentTimestamp {
                                                accessTokenData = await NotificationService().refreshAccessToken(refreshToken: customWalletModel.refreshToken ?? "", endPoint: customWalletModel.tokenEndPoint ?? "").0
                                                refreshTokenData = await NotificationService().refreshAccessToken(refreshToken: customWalletModel.refreshToken ?? "", endPoint: customWalletModel.tokenEndPoint ?? "").1
                                            } else {
                                                accessTokenData = customWalletModel.accessToken
                                                refreshTokenData = customWalletModel.refreshToken
                                            }
                                        }
                                        customWalletModel.refreshToken = refreshTokenData
                                        customWalletModel.accessToken = accessTokenData
                                        await NotificationService().sendNoticationStatus(endPoint: customWalletModel.notificationEndPont, event: NotificationStatus.credentialAccepted.rawValue, notificationID: customWalletModel.notificationID, accessToken: customWalletModel.accessToken ?? "", refreshToken: customWalletModel.refreshToken ?? "", tokenEndPoint: customWalletModel.tokenEndPoint ?? "")
                                    }
                                }
                                await self.addHistory(certModel: customWalletModel, connectionModel: connection)
                                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                            }
                            else {
                                // Note: If it is not from 'Deffered credential' flow or not from 'EBSI_V3 certificate exchange' flow, navigate to certificate preview screen
                                if customWalletModel.fundingSource != nil {
                                    let accepted = await withCheckedContinuation { continuation in
                                        showPWAPreview(customWalletModel, connection ?? CloudAgentConnectionWalletModel(), credentialModel.fundingSource
                                                        ) { accept in
                                                            continuation.resume(returning: accept)
                                                        }
                                                    }
                                } else {
                                
                                    let accepted = await withCheckedContinuation { continuation in
                                                        showCertificatePreview2(
                                                            customWalletModel,
                                                            connection ?? CloudAgentConnectionWalletModel(),
                                                            isValidOrganization: isValidOrganization, credentailDisplay: credentialDisplay
                                                        ) { accept in
                                                            continuation.resume(returning: accept)
                                                        }
                                                    }
                                }
                            }
                            let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),recipientKey: "",label: connection?.value?.orgDetails?.name ?? "", type: UpdateWalletType.trusted, id: connection?.value?.requestID ?? "", theirDid: "", myDid: connection?.value?.myDid ?? "",imageURL: connection?.value?.orgDetails?.coverImageURL ?? "" ,invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: connection?.value?.orgDetails, orgID: connection?.value?.orgDetails?.orgId)
                        } catch {
                            UIApplicationUtils.hideLoader()
                            debugPrint(error.localizedDescription)
                            return
                        }
                    } else if let credentialModel = EBSI_Credential.decode(withDictionary: dict as [String : Any]) as? EBSI_Credential {
                        let customWalletModel = CustomWalletRecordCertModel.init()
                        var subjectDict = [String: Any]()
                        if let vc = dict["vc"] as? [String: Any],
                           let credentialSubject = vc["credentialSubject"] as? [String: Any]{
                            let keys = credentialSubject.compactMap({ $0.key })
                            let values = credentialSubject.compactMap({ $0.value })
                            for i in 0..<keys.count {
                                subjectDict[keys[i]] = values[i]
                            }
                        }
                        let vc2 = Vc(context: credentialModel.vc?.context, id: credentialModel.vc?.id, type: credentialModel.vc?.type, issuer: credentialModel.vc?.issued, issuanceDate: credentialModel.vc?.issuanceDate, validFrom: credentialModel.vc?.validFrom, issued: credentialModel.vc?.issued, credentialSubject: nil)
                        let credentialModelObj = EBSI_V2_VerifiableID(jti: credentialModel.jti, sub: credentialModel.sub, iss: credentialModel.iss, vct: credentialModel.vct, vc: vc2, accounts: credentialModel.accounts, account_holder_id: credentialModel.account_holder_id, fundingSource: credentialModel.fundingSource)
                        createFallbackCredential(subjectDict, credentialModelObj, customWalletModel, connection ?? CloudAgentConnectionWalletModel(), credential_jwt: credential_jwt, format: format ?? "", accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: credentialResponse?.notificationID ?? "", tokenEndPoint: tokenEndPoint, credentialType: credentialType)
                        do {
                            if (isDeferred) {
                                // setting credential branding data
                                customWalletModel.searchableText =  deferredCacheModel?.credentialDisplay?.name?.camelCaseToWords().uppercased()
                                customWalletModel.description =  deferredCacheModel?.credentialDisplay?.description
                                customWalletModel.logo =  deferredCacheModel?.credentialDisplay?.logo?.uri
                                customWalletModel.cover =  deferredCacheModel?.credentialDisplay?.bgImage?.uri
                                customWalletModel.backgroundColor =  deferredCacheModel?.credentialDisplay?.backgroundColor
                                customWalletModel.textColor =  deferredCacheModel?.credentialDisplay?.textColor
                                customWalletModel.accessToken = deferredCacheModel?.accessToken
                                customWalletModel.refreshToken = deferredCacheModel?.refreshToken
                                customWalletModel.notificationID = credentialResponse?.notificationID
                                customWalletModel.notificationEndPont = deferredCacheModel?.notificationEndPont
                                customWalletModel.tokenEndPoint = deferredCacheModel?.tokenEndPoint
                                UIApplicationUtils.hideLoader()
                                let (_, _) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, connectionModel: connectionModel, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .inbox_EBSIOffer)
                                NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
                                UIApplicationUtils.showSuccessSnackbar(message: "data_received_offer_credentials".localizedForSDK(),navToNotifScreen:true)
                                return
                            } else if (ebsiV3Exchange == true ) {
                                UIApplicationUtils.hideLoader()
                                let (_, _) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, connectionModel: connectionModel, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .generic)
                                NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
                                //await addEBSIExchangeCertToHistory(connectionModel: connectionModel)
                                return
                            }
                            else {
                                // Note: If it is not from 'Deffered credential' flow or not from 'EBSI_V3 certificate exchange' flow, navigate to certificate preview screen
                                let accepted = await withCheckedContinuation { continuation in
                                                    showCertificatePreview2(
                                                        customWalletModel,
                                                        connection ?? CloudAgentConnectionWalletModel(),
                                                        isValidOrganization: isValidOrganization, credentailDisplay: credentialDisplay
                                                    ) { accept in
                                                        continuation.resume(returning: accept)
                                                    }
                                                }
                                
                            }
                            let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),recipientKey: "",label: connection?.value?.orgDetails?.name ?? "", type: UpdateWalletType.trusted, id: connection?.value?.requestID ?? "", theirDid: "", myDid: connection?.value?.myDid ?? "",imageURL: connection?.value?.orgDetails?.coverImageURL ?? "" ,invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: connection?.value?.orgDetails, orgID: connection?.value?.orgDetails?.orgId)
                        } catch {
                            UIApplicationUtils.hideLoader()
                            debugPrint(error.localizedDescription)
                            return
                        }
                    }
                }
                
                ////
        ////
    }
    
    func addHistory(mode: CertificatePreviewVC_Mode = .other, certModel: CustomWalletRecordCertModel?, connectionModel: CloudAgentConnectionWalletModel?) async {
        do {
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            var history = History()
            let attrArray =  certModel?.EBSI_v2?.attributes ?? []
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
            history.date = dateFormat.string(from: Date())
            history.type = HistoryType.issuedCertificate.rawValue
            history.attributes = attrArray
            switch mode {
            case .EBSI_V2,.EBSI_PDA1:
                    history.certSubType = certModel?.subType
                case .other:
                    history.certSubType = certModel?.subType
                case .Receipt:
                history.certSubType = CertSubType.Reciept.rawValue
            default:
                history.certSubType = certModel?.subType
            }
            
//            if let schemeSeperated = certDetail?.value?.schemaID?.split(separator: ":"){
//                history.name = "\(schemeSeperated[2])".uppercased()
//            } else if let name = certModel?.value?.type {
//                history.name = name
//            }
            
            var historyName = ""
            if let name = certModel?.type {
                historyName = name
            }
            
            if history.display == nil {
                history.display = CredentialDisplay(name: nil, location: nil, locale: nil, description: nil, cover: nil, logo: nil, backgroundColor: nil, textColor: nil)
            }
            let searchText = credentialDisplay?.name?.camelCaseToWords().uppercased()
            if searchText != nil {
                certModel?.searchableText  = searchText?.uppercased()
            } else {
                certModel?.searchableText  = certModel?.searchableText
            }
            history.connectionModel = connectionModel
            history.name = certModel?.searchableText ?? historyName
            history.display?.name = certModel?.searchableText
            history.display?.description = certModel?.description
            history.display?.logo = certModel?.logo
            history.display?.cover = certModel?.cover
            history.display?.backgroundColor = certModel?.backgroundColor
            history.display?.textColor = certModel?.textColor
            history.connectionModel = connectionModel
            let (success, id) = try await WalletRecord.shared.add(connectionRecordId: "", walletHandler: walletHandler, type: .dataHistory, historyModel: history)
            debugPrint("historySaved -- \(success)")
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func getEBSI_V3_connection(orgID: String? = "EBSI_V3") async -> CloudAgentConnectionWalletModel? {
        do {
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithOrgId,searchValue: orgId)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            guard let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) else { return nil}
            
            let connectionModels = Connections.decode(withDictionary: messageModel as [String : Any]) as? Connections
            let filteredRecord = connectionModels?.records.filter({ $0.value.orgID == orgID })

            guard let firstRecord = filteredRecord?.first?.dictionary as NSDictionary? else {return nil}
            let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord) as? CloudAgentConnectionWalletModel
            return connectionModel
        } catch {
            UIApplicationUtils.hideLoader()
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    func showPWAPreview(_ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, _ fundingSource: FundingSource?, completion: ((Bool) -> Void)? = nil) {
        //UIApplicationUtils.hideLoader()
        DispatchQueue.main.async {
            let searchModel = SearchItems_CustomWalletRecordCertModel.init()
            searchModel.value = customWalletModel
            let searchText = self.credentialDisplay?.name?.camelCaseToWords().uppercased()
            if searchText != nil {
                searchModel.value?.searchableText = searchText?.uppercased()
            } else {
                searchModel.value?.searchableText = searchModel.value?.searchableText
            }
            searchModel.value?.description = EBSIWallet.shared.credentialDisplay?.description
            searchModel.value?.logo = EBSIWallet.shared.credentialDisplay?.logo?.uri ?? EBSIWallet.shared.credentialDisplay?.logo?.url
            searchModel.value?.cover = EBSIWallet.shared.credentialDisplay?.bgImage?.uri ?? EBSIWallet.shared.credentialDisplay?.bgImage?.url
            searchModel.value?.backgroundColor = EBSIWallet.shared.credentialDisplay?.backgroundColor
            searchModel.value?.textColor = EBSIWallet.shared.credentialDisplay?.textColor
            searchModel.value?.addedDate = Date().epochTime
            if self.viewMode == .BottomSheet {
                let vc = PWAPreviewBottomSheet(nibName: "PWAPreviewBottomSheet", bundle: Bundle.module)
                vc.viewModel = PWAPreviewViewModel.init(walletHandle: WalletViewModel.openedWalletHandler, reqId: "", certDetail: nil, inboxId: "", certModel: searchModel, connectionModel: connectionModel, dataAgreement: nil, fundingSource: fundingSource)
                vc.viewModel?.onAccept = { accept in
                    completion?(accept)
                }
                let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                if let topVC = UIApplicationUtils.shared.getTopVC() {
                    topVC.present(sheetVC, animated: true, completion: nil)
                }
                
            } else {
                let vc = PWAPreviewViewController(nibName: "PWAPreviewViewController", bundle: Bundle.module)
                if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                    UIApplicationUtils.hideLoader()
                    vc.viewModel = PWAPreviewViewModel.init(walletHandle: WalletViewModel.openedWalletHandler, reqId: "", certDetail: nil, inboxId: "", certModel: searchModel, connectionModel: connectionModel, dataAgreement: nil, fundingSource: fundingSource)
                    vc.viewModel?.onAccept = { accept in
                        completion?(accept)
                    }
                    navVC.pushViewController(vc, animated: true)
                } else {
                    UIApplicationUtils.hideLoader()
                    vc.viewModel = PWAPreviewViewModel.init(walletHandle: WalletViewModel.openedWalletHandler, reqId: "", certDetail: nil, inboxId: "", certModel: searchModel, connectionModel: connectionModel, dataAgreement: nil, fundingSource: fundingSource)
                    vc.viewModel?.onAccept = { accept in
                        completion?(accept)
                    }
                    //Fixme - it was push
                    UIApplicationUtils.shared.getTopVC()?.present(vc: vc)
                }
            }
        }
    }
    
    fileprivate func createFallbackCredential(_ credentialDict: Any , _ credentialModel: EBSI_V2_VerifiableID, _ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, credential_jwt: String, format: String, accessToken: String, refreshToken: String, notificationEndPoint: String, notificationID: String, tokenEndPoint: String, credentialType: String? = nil) {
        
        if credentialModel.vct == "VerifiablePortableDocumentA1" ||
            ((credentialModel.vc?.type?.contains("VerifiablePortableDocumentA1")) == true) ||
            ((credentialModel.vc?.type?.contains("PortableDocumentA1")) == true) ||
            credentialModel.vct == "PortableDocumentA1" {
            guard let credentialDict = credentialDict as? [String: Any] else { return }
            let section1 = credentialDict["section1"] != nil ? decodePDA1SectionFromDict(credentialDict["section1"] as Any, as: Section1.self) : nil
            let section2 = credentialDict["section2"] != nil ? decodePDA1SectionFromDict(credentialDict["section2"] as Any, as: Section2.self) : nil
            let section3 = credentialDict["section3"] != nil ? decodePDA1SectionFromDict(credentialDict["section3"] as Any, as: Section3.self) : nil
            let section4 = credentialDict["section4"] != nil ? decodePDA1SectionFromDict(credentialDict["section4"] as Any, as: Section4.self) : nil
            let section5 = credentialDict["section5"] != nil ? decodePDA1SectionFromDict(credentialDict["section5"] as Any, as: Section5.self) : nil
            let section6 = credentialDict["section6"] != nil ? decodePDA1SectionFromDict(credentialDict["section6"] as Any, as: Section6.self) : nil
            OpenIdPDA1Parser.shared.createPDA(section1, section2, section3, section4, section5, section6, customWalletModel, connectionModel , credentialModel: credentialModel, credential_jwt, format: format,accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: notificationID, tokenEndPoint: tokenEndPoint)
        } else if credentialModel.vct == "eu.europa.ec.eudi.photoid.1" {
            guard let credentialDict = credentialDict as? [String: Any] else { return }
            let iso23220 = credentialDict["iso23220"] != nil ? decodePDA1SectionFromDict(credentialDict["iso23220"] as Any, as: Iso23220.self) : nil
            let photoID = credentialDict["photoid"] != nil ? decodePDA1SectionFromDict(credentialDict["photoid"] as Any, as: Photoid.self) : nil
            
            PhotoIDParser.shared.createPhotoID(dict: [:], customWalletModel: customWalletModel, credential_jwt: credential_jwt, credentialModel: credentialModel, format: format, connectionModel: connectionModel, accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: notificationID, tokenEndPoint: tokenEndPoint, photoID: photoID, iso: iso23220)
            
        } else if (credentialModel.vct == "Receipt" || credentialModel.vct == "VerifiablevReceiptSDJWT"), let receiptModel = decodePDA1SectionFromDict(credentialDict as Any, as: ReceiptItemModel.self) {
            guard let credentialDict = credentialDict as? [String: Any] else { return }
            createReceipt(receiptModel, customWalletModel, connectionModel, credentialModel: credentialModel, credential_jwt, format: format, credDict: credentialDict)
        } else {
            let attributes = convertToOutputFormat(data : credentialDict)
            customWalletModel.referent = nil
            customWalletModel.schemaID = nil
            customWalletModel.certInfo = nil
            customWalletModel.connectionInfo = connectionModel
            customWalletModel.type = CertType.EBSI.rawValue
            customWalletModel.format = format
            var credentialTypeValue  = credentialType ?? ""
            if credentialModel.vc?.type?.count ?? 0 > 0 {
                credentialTypeValue = fetchCredentialType(list: credentialModel.vc?.type ?? ["OpenID credential"]) ?? ""
            }
            // check if credentialType is walletunit attestation then no need to cange else set according to vct
            
            customWalletModel.subType =  credentialTypeValue.camelCaseToWords().uppercased()
            if credentialModel.vct == "WalletUnitAttestation" {
                customWalletModel.searchableText = credentialDisplay?.name?.camelCaseToWords().uppercased() ??  credentialTypeValue.camelCaseToWords().uppercased()
            } else {
                customWalletModel.searchableText = credentialTypeValue.camelCaseToWords().uppercased()
            }
            customWalletModel.vct = credentialModel.vct
            customWalletModel.accessToken = accessToken
            customWalletModel.refreshToken = refreshToken
            customWalletModel.notificationID = notificationID
            customWalletModel.notificationEndPont = notificationEndPoint
            customWalletModel.tokenEndPoint = tokenEndPoint
            customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel.iss, credentialJWT: credential_jwt)
        }
    }
    
    fileprivate func createStudentId(_ data: Identifier, _ credentialModel: EBSI_V2_VerifiableID, _ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, _ credential_jwt: String, accessToken: String = "", refreshToken: String = "", notificationEndPoint: String = "", notificationID: String = "", tokenEndPoint: String = "") {
        //Student ID
        let attributes = [
            IDCardAttributes.init(name: "Scheme ID", value: data.schemeID),
            IDCardAttributes.init(name: "Value", value: data.value),
            IDCardAttributes.init(name: "Id", value: credentialModel.vc?.credentialSubject?.id ?? "", schemeID: "ID"),
        ]
        customWalletModel.referent = nil
        customWalletModel.schemaID = nil
        customWalletModel.certInfo = nil
        customWalletModel.connectionInfo = connectionModel
        customWalletModel.type = CertType.EBSI.rawValue
        customWalletModel.subType = EBSI_CredentialType.StudentID.rawValue
        customWalletModel.searchableText = EBSI_CredentialSearchText.StudentID.rawValue
        customWalletModel.vct = credentialModel.vct
        customWalletModel.accessToken = accessToken
        customWalletModel.refreshToken = refreshToken
        customWalletModel.notificationID = notificationID
        customWalletModel.notificationEndPont = notificationEndPoint
        customWalletModel.tokenEndPoint = tokenEndPoint
        customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel.iss, credentialJWT: credential_jwt)
    }
    
    fileprivate func createDiplomaCertificate(_ data: Achieved, _ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, _ credentialModel: EBSI_V2_VerifiableID, _ credential_jwt: String, accessToken: String = "", refreshToken: String = "", notificationEndPoint: String = "", notificationID: String = "", tokenEndPoint: String = "") {
        //Diploma
        let attributes = [
            IDCardAttributes.init(name: "Scheme ID", value: data.identifier?.first?.schemeID),
            IDCardAttributes.init(name: "Value", value: data.identifier?.first?.value),
            IDCardAttributes.init(name: "Eqfl Level", value: data.specifiedBy?.first?.eqflLevel),
            IDCardAttributes.init(name: "Title", value: data.specifiedBy?.first?.title),
            IDCardAttributes.init(name: "Awarding Location", value: data.wasAwardedBy?.awardingLocation?.first),
            IDCardAttributes.init(name: "Awarding Date", value: data.wasAwardedBy?.awardingDate),
            IDCardAttributes.init(name: "Awarding Body", value: data.wasAwardedBy?.awardingBody?.first),
            IDCardAttributes.init(name: "id", value: data.wasAwardedBy?.id)
        ]
        customWalletModel.referent = nil
        customWalletModel.schemaID = nil
        customWalletModel.certInfo = nil
        customWalletModel.connectionInfo = connectionModel
        customWalletModel.type = CertType.EBSI.rawValue
        customWalletModel.subType = EBSI_CredentialType.Diploma.rawValue
        customWalletModel.searchableText = EBSI_CredentialSearchText.Diploma.rawValue
        customWalletModel.vct = credentialModel.vct
        customWalletModel.accessToken = accessToken
        customWalletModel.refreshToken = refreshToken
        customWalletModel.notificationID = notificationID
        customWalletModel.notificationEndPont = notificationEndPoint
        customWalletModel.tokenEndPoint = tokenEndPoint
        customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel.iss, credentialJWT: credential_jwt)
    }
    
    func createReceipt(_ receiptModel: ReceiptItemModel?, _ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, credentialModel: EBSI_V2_VerifiableID? = nil, _ credential_jwt: String, format: String, searchableText: String = "", accessToken: String = "", refreshToken: String = "", notificationEndPoint: String = "", notificationID: String = "", tokenEndPoint: String = "", credDict: [String: Any]) {
            let attributes =  EBSIWallet.shared.convertToOutputFormat(data : credDict)
            let credentialType = EBSIWallet.shared.fetchCredentialType(list: credentialModel?.vc?.type)
            customWalletModel.referent = nil
            customWalletModel.schemaID = nil
            customWalletModel.certInfo = nil
            customWalletModel.connectionInfo = connectionModel
            customWalletModel.type = CertType.EBSI.rawValue
        customWalletModel.subType = credentialType
            customWalletModel.searchableText = credentialType?.camelCaseToWords().uppercased() ??  EBSI_CredentialSearchText.PDA1.rawValue.uppercased()
            customWalletModel.format = format
            customWalletModel.vct = credentialModel?.vct
            customWalletModel.accessToken = accessToken
            customWalletModel.refreshToken = refreshToken
        customWalletModel.receiptData = receiptModel
            customWalletModel.notificationID = notificationID
            customWalletModel.notificationEndPont = notificationEndPoint
            customWalletModel.tokenEndPoint = tokenEndPoint
            customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel?.iss, credentialJWT: credential_jwt)
        }
    
    func fetchCredentialType(list:[String]?) -> String? {
        let credentialType = list?.count ?? 0 > 0 ? list?.last : "Credential"
        
        do {
            let responseModel = issuerConfig
            
            if let credential = responseModel?.credentialsSupported?.dataSharing?[credentialType ?? ""] {
                let disp = EBSIWallet.shared.getDisplayName(display: credential.display)
                if disp == nil {
                    return credentialType
                } else {
                    return disp
                }
            }
                
            return credentialType
        } catch {
            // Handle errors here
            print("Error decoding JSON:", error)
            return credentialType
        }
    }
    
    func decodePDA1SectionFromDict<T: Codable>(_ sectionData: Any, as type: T.Type) -> T? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sectionData)
            let decodedSection = try JSONDecoder().decode(type, from: jsonData)
            return decodedSection
        } catch {
            print("Failed to decode \(type) with error: \(error)")
            return nil
        }
    }
    
    func getDisplayName(display:[Display]?) -> String?{
        var displayName : String?
        
        if ((display?.isEmpty) == true) {
            displayName = nil
        } else {
            displayName = display?[0].name
        }
       
        return displayName
    }
    
    func convertToOutputFormat(data: Any, parentKey: String? = nil) -> [IDCardAttributes] {
        var output: [IDCardAttributes] = []
        
        if let dict = data as? [String: Any] {
            for (key, value) in dict {
                let name = parentKey != nil ? "\(parentKey!) \(key)" : key
                if key == "_sd" {
                    
                } else if let nestedDict = value as? [String: Any] {
                    let nestedOutput = convertToOutputFormat(data: nestedDict, parentKey: name)
                    output.append(contentsOf: nestedOutput)
                } else if let array = value as? [String] {
                    for (index, element) in array.enumerated() {
                        var type: CertAttributesTypes? = .string
                        if key == "signature" || key == "image", let value = value as? String, isBase64(string: value) {
                            type = .image
                        }
                        let pair = IDCardAttributes(type: type, name: "\(name)[\(index)]".replacingOccurrences(of: "_", with: " ").camelCaseToWords(), value: element)
                        output.append(pair)
                    }
                } else if let array = value as? [Any] {
                    for (index, element) in array.enumerated() {
                        let nestedOutput = convertToOutputFormat(data: element, parentKey: "\(name)[\(index)]")
                        output.append(contentsOf: nestedOutput)
                    }
                } else if let stringValue = value as? String {
                    var type: CertAttributesTypes? = .string
                    if key == "signature" || key == "image", let value = value as? String, isBase64(string: value) {
                        type = .image
                    }
                    let pair = IDCardAttributes(type: type, name: name.replacingOccurrences(of: "_", with: " ").camelCaseToWords(), value: stringValue)
                    output.append(pair)
                } else if let anyValue = value as? Int {
                    let type: CertAttributesTypes? = .string
                    let stringValue = String(anyValue)
                    let pair = IDCardAttributes(type: type, name: name.replacingOccurrences(of: "_", with: " ").camelCaseToWords(), value: stringValue)
                    output.append(pair)
                }
            }
        }
        
        return output
    }
    
    func isBase64(_ value: String) -> Bool {
        if let data = Data(base64Encoded: value), !data.isEmpty {
            return true
        }
        return false
    }
    
    func isBase64(string: String) -> Bool {
        if string.hasPrefix("data:image") {
            if let commaRange = string.range(of: ",") {
                let base64String = String(string[commaRange.upperBound...])
                guard let data = Data(base64Encoded: base64String) else { return false }
                return UIImage(data: data) != nil
            } else {
                return false
            }
        } else {
            guard let data = Data(base64Encoded: string) else { return false }
            return UIImage(data: data) != nil
        }
    }
    
    fileprivate func showCertificatePreview2(_ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, isValidOrganization: Bool? = false, credentailDisplay: Display? = nil, completion: ((Bool) -> Void)? = nil) {
        UIApplicationUtils.hideLoader()
        DispatchQueue.main.async {
            if customWalletModel.vct == "Receipt" || customWalletModel.vct == "VerifiablevReceiptSDJWT" {
                let searchModel = SearchItems_CustomWalletRecordCertModel.init()
                searchModel.value = customWalletModel
                let searchText = self.credentialDisplay?.name?.camelCaseToWords().uppercased()
                if searchText != nil {
                    searchModel.value?.searchableText = searchText?.uppercased()
                } else {
                    searchModel.value?.searchableText = searchModel.value?.searchableText
                }
                searchModel.value?.description = EBSIWallet.shared.credentialDisplay?.description
                searchModel.value?.logo = EBSIWallet.shared.credentialDisplay?.logo?.uri ?? EBSIWallet.shared.credentialDisplay?.logo?.url
                searchModel.value?.cover = EBSIWallet.shared.credentialDisplay?.bgImage?.uri ?? EBSIWallet.shared.credentialDisplay?.bgImage?.url
                searchModel.value?.backgroundColor = EBSIWallet.shared.credentialDisplay?.backgroundColor
                searchModel.value?.textColor = EBSIWallet.shared.credentialDisplay?.textColor
                if self.viewMode == .BottomSheet {
                    let vc = ReceiptBottomSheetVC(nibName: "ReceiptBottomSheetVC", bundle: UIApplicationUtils.shared.getResourcesBundle())
                    vc.viewModel.certModel = searchModel
                    vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                    vc.viewModel.connectionModel = connectionModel
                    vc.onAccept = { accept in
                        completion?(accept)
                    }
                    let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                    vc.modalPresentationStyle = .overCurrentContext
                    
                    if let topVC = UIApplicationUtils.shared.getTopVC() {
                        topVC.present(sheetVC, animated: false, completion: nil)
                    }
                } else {
                    let vc = ReceiptViewController(nibName: "ReceiptViewController", bundle: UIApplicationUtils.shared.getResourcesBundle())
                    vc.viewModel.certModel = searchModel
                    vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                    vc.viewModel.connectionModel = connectionModel
                    vc.onAccept = { accept in
                        completion?(accept)
                    }
                    if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                        UIApplicationUtils.hideLoader()
                        navVC.pushViewController(vc, animated: true)
                    } else {
                        //Fixme - it was push
                        UIApplicationUtils.hideLoader()
                        UIApplicationUtils.shared.getTopVC()?.present(vc: vc)
                    }
                }
            } else if customWalletModel.vct == "VerifiableFerryBoardingPassCredentialSDJWT" {
                let searchModel = SearchItems_CustomWalletRecordCertModel.init()
                searchModel.value = customWalletModel
                let searchText = self.credentialDisplay?.name?.camelCaseToWords().uppercased()
                if searchText != nil {
                    searchModel.value?.searchableText = searchText?.uppercased()
                } else {
                    searchModel.value?.searchableText = searchModel.value?.searchableText
                }
                searchModel.value?.description = EBSIWallet.shared.credentialDisplay?.description
                searchModel.value?.logo = EBSIWallet.shared.credentialDisplay?.logo?.uri ?? EBSIWallet.shared.credentialDisplay?.logo?.url
                searchModel.value?.cover = EBSIWallet.shared.credentialDisplay?.bgImage?.uri ?? EBSIWallet.shared.credentialDisplay?.bgImage?.url
                searchModel.value?.backgroundColor = EBSIWallet.shared.credentialDisplay?.backgroundColor
                searchModel.value?.textColor = EBSIWallet.shared.credentialDisplay?.textColor
                if self.viewMode == .BottomSheet {
                    let vc = BoardingPassBottomSheetVC(nibName: "BoardingPassBottomSheetVC", bundle: UIApplicationUtils.shared.getResourcesBundle())
                    vc.viewModel.certModel = searchModel
                    vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                    vc.viewModel.connectionModel = connectionModel
                    vc.onAccept = { accept in
                        completion?(accept)
                    }
                    let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                    vc.modalPresentationStyle = .overCurrentContext
                    
                    if let topVC = UIApplicationUtils.shared.getTopVC() {
                        topVC.present(sheetVC, animated: false, completion: nil)
                    }
                } else {
                    let vc = BoardingPassViewController(nibName: "BoardingPassViewController", bundle: UIApplicationUtils.shared.getResourcesBundle())
                    vc.viewModel.certModel = searchModel
                    vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                    vc.viewModel.connectionModel = connectionModel
                    vc.onAccept = { accept in
                        completion?(accept)
                    }
                    if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                        UIApplicationUtils.hideLoader()
                        navVC.pushViewController(vc, animated: true)
                    } else {
                        UIApplicationUtils.hideLoader()
                        //Fixme - it was push
                        UIApplicationUtils.shared.getTopVC()?.present(vc: vc)
                    }
                }
            } else {
                
                let searchModel = SearchItems_CustomWalletRecordCertModel.init()
                searchModel.value = customWalletModel
                let searchText = credentailDisplay?.name?.camelCaseToWords().uppercased()
                if searchText != nil {
                    searchModel.value?.searchableText = searchText?.uppercased()
                } else {
                    searchModel.value?.searchableText = searchModel.value?.searchableText
                }
                searchModel.value?.description = credentailDisplay?.description
                searchModel.value?.logo = credentailDisplay?.logo?.uri ?? credentailDisplay?.logo?.url
                searchModel.value?.cover = credentailDisplay?.bgImage?.uri ?? credentailDisplay?.bgImage?.url
                searchModel.value?.backgroundColor = credentailDisplay?.backgroundColor
                searchModel.value?.textColor = credentailDisplay?.textColor
                
                if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "CertificatePreviewViewController") as? CertificatePreviewViewController {
                    controller.viewModel = CertificatePreviewViewModel.init(walletHandle: WalletViewModel.openedWalletHandler, reqId: "", certDetail: nil, inboxId: "", certModel: searchModel, connectionModel: connectionModel, dataAgreement: nil)
                    controller.mode = .EBSI_V2
                    if (customWalletModel.subType == EBSI_CredentialSearchText.PDA1.rawValue || customWalletModel.subType == EBSI_CredentialType.PDA1.rawValue)  {
                        controller.mode = .EBSI_PDA1
                    } else if customWalletModel.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
                        controller.mode = .PhotoIDWithAgeBadge
                    }
                    controller.onAccept = { accept in
                        completion?(accept)
                    }
                    if self.viewMode == .BottomSheet {
                        let walletVC = CertificatePreviewBottomSheet(nibName: "CertificatePreviewBottomSheet", bundle: UIApplicationUtils.shared.getResourcesBundle())
                        walletVC.viewModel = CertificatePreviewViewModel.init(walletHandle: WalletViewModel.openedWalletHandler, reqId: "", certDetail: nil, inboxId: "", certModel: searchModel, connectionModel: connectionModel, dataAgreement: nil)
                        walletVC.mode = .EBSI_V2
                        if (customWalletModel.subType == EBSI_CredentialSearchText.PDA1.rawValue || customWalletModel.subType == EBSI_CredentialType.PDA1.rawValue)  {
                            walletVC.mode = .EBSI_PDA1
                        } else if customWalletModel.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
                            walletVC.mode = .PhotoIDWithAgeBadge
                        }
                        walletVC.onAccept = { accept in
                            completion?(accept)
                        }
                        walletVC.viewMode = .BottomSheet
                            
                        let sheetVC = WalletHomeBottomSheetViewController(contentViewController: walletVC)
                        sheetVC.modalPresentationStyle = .overCurrentContext
                        
                        if let topVC = UIApplicationUtils.shared.getTopVC() {
                            topVC.present(sheetVC, animated: false, completion: nil)
                        }
                    } else {
                        if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController{
                            navVC.pushViewController(controller, animated: true)
                        } else{
                            //Fixme - it was push
                            UIApplicationUtils.shared.getTopVC()?.push(vc: controller)
                        }
                    }
                }
            }
//            }
        }
    }
}


extension EBSIWallet{
    func getEBSI_V2_attributes(section: Int, certModel: SearchItems_CustomWalletRecordCertModel?) -> [IDCardAttributes] {
        var attrArray: [IDCardAttributes] = []
        switch certModel?.value?.subType ?? "" {
        case EBSI_CredentialType.Diploma.rawValue:
            switch section {
            case 0: attrArray = certModel?.value?.EBSI_v2?.attributes?.filter({ e in
                return e.name == "Scheme ID" || e.name == "Value"
            }) ?? []
            case 1: attrArray = certModel?.value?.EBSI_v2?.attributes?.filter({ e in
                return e.name == "Eqfl Level" || e.name == "Title"
            }) ?? []
            case 2: attrArray = certModel?.value?.EBSI_v2?.attributes?.filter({ e in
                return e.name == "Awarding Location" || e.name == "Awarding Date" || e.name == "Awarding Body" || e.name == "Id"
            }) ?? []
            default: break
            }
        default:
            attrArray = certModel?.value?.EBSI_v2?.attributes ?? []
        }
        return attrArray
    }
    
    func getEBSI_V2_attributes(section: Int, history: History?) -> [IDCardAttributes] {
        var attrArray: [IDCardAttributes] = []
        switch history?.certSubType ?? "" {
        case EBSI_CredentialType.Diploma.rawValue:
            switch section {
            case 0: attrArray = history?.attributes?.filter({ e in
                return e.name == "Scheme ID" || e.name == "Value"
            }) ?? []
            case 1: attrArray = history?.attributes?.filter({ e in
                return e.name == "Eqfl Level" || e.name == "Title"
            }) ?? []
            case 2: attrArray = history?.attributes?.filter({ e in
                return e.name == "Awarding Location" || e.name == "Awarding Date" || e.name == "Awarding Body" || e.name == "Id"
            }) ?? []
            default: break
            }
        default:
            attrArray = history?.attributes ?? []
        }
        return attrArray
    }
    
    func clearCredentialRequestCache() {
        EBSIWallet.shared.credentialOffer = nil
        EBSIWallet.shared.openIdIssuerResponseData = nil
        EBSIWallet.shared.issuerConfig = nil
        EBSIWallet.shared.isDynamicCredentialRequest = false
        EBSIWallet.shared.credentialDisplay = nil
        tokenEndpointForConformanceFlow = nil
        authServerUrlString = nil
        jwksUrlString = nil
        privateKeyData = nil
        codeVerifierCreated = ""
        presentationRequestJwt = ""
        dynamicCredentialCount = 0
        EBSIWallet.shared.dcqlQuery = nil
        EBSIWallet.shared.isFromPushNotification = false
        EBSIWallet.shared.otpFlowHandler = nil
    }
}

extension EBSIWallet {
    @available(iOS 14.0, *)
    func checkEBSI_QR(code: String) async -> Bool {
        clearCredentialRequestCache()
        //Check EBSI
        if code.contains("presentation_definition=") || code.contains("request_uri=") || code.contains("presentation_definition_uri=") {
//            Task{
                let presentationRequestData = await self.verificationHandler?.processAuthorisationRequest(data: code)
                let presentationRequest = presentationRequestData?.0
                if presentationRequestData?.1 != nil {
                    UIApplicationUtils.hideLoader()
                    UIApplicationUtils.showErrorSnackbar(message: presentationRequestData?.1?.message ?? "Invalid QR code")
                } else {
                    dcqlQuery = presentationRequest?.dcqlQuery
                    let urlString = "openid4vp://?client_id=\(presentationRequest?.clientId ?? "")&response_type=\(presentationRequest?.responseType ?? "")&scope=\(presentationRequest?.scope ?? "")&redirect_uri=\(presentationRequest?.redirectUri ?? presentationRequest?.responseUri ?? "")&request_uri=\(presentationRequest?.requestUri ?? "")&response_mode=\(presentationRequest?.responseMode ?? "")&state=\(presentationRequest?.state ?? "")&nonce=\(presentationRequest?.nonce ?? "")&client_metadata=\(presentationRequest?.clientMetaData ?? "")&client_id_scheme=\(presentationRequest?.clientIDScheme ?? "")"
                    var clientID = presentationRequest?.clientId
                    
                    //                if ((URL(string: code)?.queryParameters?["client_id"]?.isValidURL) != nil){
                    //                    clientID = URL(string: code)?.queryParameters?["client_id"] ?? ""
                    //                }
                   let credIssuer = clientID ?? credentialOffer?.credentialIssuer ?? ""
                    let exchageID = clientID ?? ""
                    var newOrgID: String = ""
                    var newExchangeId : String = ""
                    if let isDraft = DraftSuffixProcessor().isDraftID(credIssuer), isDraft {
                        newOrgID = DraftSuffixProcessor().removeDraftSuffix(from: credIssuer) ?? ""
                    } else {
                        newOrgID = credIssuer
                    }
                    
                    if let isDraft = DraftSuffixProcessor().isDraftID(exchageID), isDraft {
                        newExchangeId = DraftSuffixProcessor().removeDraftSuffix(from: exchageID) ?? ""
                    } else {
                        newExchangeId = exchageID
                    }
                    self.credentialIssuer = newOrgID
                    exchangeClientID = newExchangeId
                    presentationRequestJwt = presentationRequest?.request ?? ""
                    await EBSIWallet.shared.processVerifiablePresentationExchange(uri: urlString, presentationDefinition: presentationRequest?.presentationDefinition ?? "", clientMetaData: presentationRequest?.clientMetaData ?? "", transactionData: presentationRequest?.transactionData ?? [])
                }
//            }
            return true
        } else if code.contains("openid://initiate_issuance"){
            EBSIWallet.shared.configureWalletForV2EBSIversion(issuerCode: code, isFromShareData: true)
            return true
        } else if code.contains("openid://?"){
//            Task{
                let code_url = URL.init(string: code)
                let conformance = code_url?.queryParameters?["conformance"] as? String ?? ""
                let connectionModel = await EBSIWallet.shared.getEBSI_V2_connection()
                let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
                DispatchQueue.main.async {
                    if let vc = ExchangeDataPreviewViewController().initialize() as? ExchangeDataPreviewViewController {
                        vc.viewModel = ExchangeDataPreviewViewModel.init(walletHandle: walletHandler, connectionModel: connectionModel, conformance: conformance)
                        vc.mode = .EBSI
                        if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                            navVC.pushViewController(vc, animated: true)
                        } else {
                            UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
                        }
                    }
                }
//            }
            return true
        } else if code.contains("credential_offer=") || code.contains("credential_offer_uri=")  {
//            Task {
//                let keyIDfromKeyChain = WalletUnitAttestationService().retrieveKeyIdFromKeychain()
//                if keyIDfromKeyChain == "" || keyIDfromKeyChain == nil {
//                    keyIDforWUA = try await WalletUnitAttestationService().generateKeyId()
//                    WalletUnitAttestationService().storeKeyIdInKeychain(keyIDforWUA)
//                } else {
//                    keyIDforWUA = keyIDfromKeyChain ?? ""
//                }
                
            processCredentialOffer(uri: code)
            return true
//            }
        }
        return false
    }
    
    func storeKeyIdInKeychain(_ keyId: String) {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "AppAttestationKeyId",
            kSecValueData as String: keyId.data(using: .utf8)!
        ]
        
        SecItemDelete(keychainQuery as CFDictionary)
        
        // Add the new keyId
        let status = SecItemAdd(keychainQuery as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("KeyId successfully stored in Keychain.")
        } else {
            print("Failed to store KeyId in Keychain: \(status)")
        }
    }
    
    func generateKeyId() async throws -> String {
        let service = DCAppAttestService.shared
        return try await withCheckedThrowingContinuation { continuation in
            service.generateKey { keyId, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let keyId = keyId {
                    continuation.resume(returning: keyId)
                } else {
                    continuation.resume(throwing: NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Key generation failed"]))
                }
            }
        }
    }
    
    func updateCredentialWithJWT(jwt:String, searchableText: String = "", addedDate: String = "") -> CustomWalletRecordCertModel {
        let credential_jwt_parts = jwt.split(separator: ".")
        let credential_jwt_payload = "\(credential_jwt_parts[safe: 1] ?? "")"
//        let credential = credential_jwt_payload.decodeBase64() ?? ""
        
        let tempCredential = SDJWTUtils.shared.updateIssuerJwtWithDisclosures(credential: jwt)
        let dict = UIApplicationUtils.shared.convertToDictionary(text: tempCredential ?? "{}") ?? [:]
        
        var customWalletModel = CustomWalletRecordCertModel.init()
        
        let dictionary = convertStringTypeToArray(dict: dict as [String : Any])
        
        if let credentialModel = EBSI_V2_VerifiableID.decode(withDictionary: dictionary as [String : Any]) as? EBSI_V2_VerifiableID {
            
                var subjectDict = [String: Any]()
                if let vc = dictionary["vc"] as? [String: Any],
                   let credentialSubject = vc["credentialSubject"] as? [String: Any]{
                    let keys = credentialSubject.compactMap({ $0.key })
                    let values = credentialSubject.compactMap({ $0.value })
                    
                    for i in 0..<keys.count {
                        subjectDict[keys[i]] = values[i]
                    }
                } else {
                    let keys = dictionary.compactMap({ $0.key})
                    let values = dictionary.compactMap({ $0.value })
                    
                    for i in 0..<keys.count {
                        if keys[i] != "iss" && keys[i] != "iat" && keys[i] != "vct" && keys[i] != "_sd" && keys[i] != "_sd_alg" && keys[i] != "jti" &&  keys[i] != "cnf" &&  keys[i] != "sub" &&  keys[i] != "nbf" && keys[i] != "exp" && keys[i] != "status" {
                            subjectDict[keys[i]] = values[i]
                        }
                    }
                }
                customWalletModel = createFallbackCredentialWithResponse(subjectDict, credentialModel, customWalletModel, connectionModel, credential_jwt: jwt, searchableText: searchableText, addedDate: addedDate) ?? customWalletModel
        } else if let credentialModel = EBSI_Credential.decode(withDictionary: dict as [String : Any]) as? EBSI_Credential {
            var subjectDict = [String: Any]()
            if let vc = dict["vc"] as? [String: Any],
              let credentialSubject = vc["credentialSubject"] as? [String: Any]{
              let keys = credentialSubject.compactMap({ $0.key })
              let values = credentialSubject.compactMap({ $0.value })
              for i in 0..<keys.count {
                subjectDict[keys[i]] = values[i]
              }
            }
            let vc2 = Vc(context: credentialModel.vc?.context, id: credentialModel.vc?.id, type: credentialModel.vc?.type, issuer: credentialModel.vc?.issued, issuanceDate: credentialModel.vc?.issuanceDate, validFrom: credentialModel.vc?.validFrom, issued: credentialModel.vc?.issued, credentialSubject: nil)
            let credentialModelObj = EBSI_V2_VerifiableID(jti: credentialModel.jti, sub: credentialModel.sub, iss: credentialModel.iss, vct: credentialModel.vct, vc: vc2, accounts: credentialModel.accounts, account_holder_id: credentialModel.account_holder_id, fundingSource: credentialModel.fundingSource)
            customWalletModel = createFallbackCredentialWithResponse(subjectDict, credentialModelObj, customWalletModel, connectionModel, credential_jwt: jwt, searchableText: searchableText, addedDate: addedDate) ?? customWalletModel
        }
        return customWalletModel
    }
    
    func createFallbackCredentialWithResponse(_ credentialDict: Any , _ credentialModel: EBSI_V2_VerifiableID, _ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, credential_jwt: String, searchableText: String, addedDate: String = "") -> CustomWalletRecordCertModel?{
        
        if credentialModel.vct == "VerifiablePortableDocumentA1" ||
            ((credentialModel.vc?.type?.contains("VerifiablePortableDocumentA1")) == true) ||
            ((credentialModel.vc?.type?.contains("PortableDocumentA1")) == true) ||
            credentialModel.vct == "PortableDocumentA1" {
            guard let credentialDict = credentialDict as? [String: Any] else { return nil}
            let section1 = credentialDict["section1"] != nil ? decodePDA1SectionFromDict(credentialDict["section1"] as Any, as: Section1.self) : nil
            let section2 = credentialDict["section2"] != nil ? decodePDA1SectionFromDict(credentialDict["section2"] as Any, as: Section2.self) : nil
            let section3 = credentialDict["section3"] != nil ? decodePDA1SectionFromDict(credentialDict["section3"] as Any, as: Section3.self) : nil
            let section4 = credentialDict["section4"] != nil ? decodePDA1SectionFromDict(credentialDict["section4"] as Any, as: Section4.self) : nil
            let section5 = credentialDict["section5"] != nil ? decodePDA1SectionFromDict(credentialDict["section5"] as Any, as: Section5.self) : nil
            let section6 = credentialDict["section6"] != nil ? decodePDA1SectionFromDict(credentialDict["section6"] as Any, as: Section6.self) : nil
            let model = OpenIdPDA1Parser.shared.createPDAWithResponse(section1, section2, section3, section4, section5, section6, customWalletModel, connectionModel , credentialModel: credentialModel, credential_jwt, searchableText: searchableText)
            model.addedDate = addedDate
            return model
        } else if credentialModel.vct == "eu.europa.ec.eudi.photoid.1" {
            guard let credentialDict = credentialDict as? [String: Any] else { return nil}
            let iso23220 = credentialDict["iso23220"] != nil ? decodePDA1SectionFromDict(credentialDict["iso23220"] as Any, as: Iso23220.self) : nil
            let photoID = credentialDict["photoid"] != nil ? decodePDA1SectionFromDict(credentialDict["photoid"] as Any, as: Photoid.self) : nil
            let model = PhotoIDParser.shared.createPhotoIDWithResponse(dict: [:], customWalletModel: customWalletModel, credential_jwt: credential_jwt, credentialModel: credentialModel, format: "", connectionModel: connectionModel, photoID: photoID, iso: iso23220)
            model?.addedDate = addedDate
            return model
        } else if credentialModel.vct == "PaymentWalletAttestation" {
            let model = OpenIdPWACredentialParser.shared.createPWACredentialWithResponse(customWalletModel, connectionModel , credentialModel, credential_jwt, searchableText: searchableText, credentialDict: credentialDict)
            return model
        } else {
            let walletModel = customWalletModel
            let attributes = convertToOutputFormat(data : credentialDict)
            
            walletModel.referent = nil
            walletModel.schemaID = nil
            walletModel.certInfo = nil
            walletModel.connectionInfo = connectionModel
            walletModel.type = CertType.EBSI.rawValue
            walletModel.addedDate = addedDate
            
            var credentialType  = EBSIWallet.shared.credentialOffer?.credentials?.first?.types?.last ?? ""
            if credentialModel.vc?.type?.count ?? 0 > 0 {
                //credentialType = fetchCredentialType(list: credentialModel.vc?.type ?? ["OpenID credential"], issuerConfig: issuerConfig) ?? ""
            }
        
        walletModel.subType =  searchableText.camelCaseToWords().uppercased()
        walletModel.searchableText = searchableText.camelCaseToWords().uppercased()
        walletModel.vct = credentialModel.vct
        walletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel.iss, credentialJWT: credential_jwt)
        
        return walletModel
    }
    }
    
    func convertStringTypeToArray(dict: [String: Any]) -> [String: Any] {
        var dict = dict
        if var valueDict = dict["vc"] as? [String: Any] {
            if var typeValue = valueDict["type"] {
                if let typeArray = typeValue as? [String] {
                } else if let typeString = typeValue as? String {
                    valueDict["type"] = [typeString]
                }
            }
            dict["vc"] = valueDict
        }
        return dict
    }
    
    func convertClientMetaDataToDisplay(clientMetaData: ClientMetaData?) -> Display {
        return Display(mName: clientMetaData?.clientName ?? "Unknown Org", mLocation: clientMetaData?.location ?? "Not Discoverable", mLocale: "en", mDescription: clientMetaData?.description ?? "", mCover: DisplayCover(mUrl: clientMetaData?.coverUri, mAltText: nil), mLogo: DisplayCover(mUrl: clientMetaData?.logoUri ?? "https://storage.googleapis.com/data4diabetes/unknown.png", mAltText: nil), mBackgroundColor: nil, mTextColor: nil)
    }
    
    
    func processDataForVPExchange() {
        
        Task {
            var jwtList = [String]()
            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
            CredentialManager.shared.checkCredentialExpiry { success in
                AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates,searchType: .withoutQuery) { (success, searchHandler, error) in
                    AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [self] (fetched, response, error) in
                        let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                        let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                        Task {
                            let credentialJWT = searchResponse?.records?.compactMap { $0.value?.EBSI_v2?.credentialJWT }
                            let keyHandler = SecureEnclaveHandler(keyID: keyHandlerKeyID)
                            self.revokedList = await CredentialRevocationService().getRevokedCredentials(credentialList: credentialJWT ?? [], keyHandler: keyHandler)
                            let revokedRecords =  searchResponse?.records?.filter { record in
                                revokedList.contains(record.value?.EBSI_v2?.credentialJWT ?? "")
                            }
                            for data in revokedRecords ?? [] {
                                CredentialManager.shared.removeFromActiveWallet(data) { success in
                                    if success {
                                        // currenlty no need to show the toast, but keeping it for future implementation
                                        DispatchQueue.main.async {
                                            NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                                        }
                                        CredentialManager.shared.addRevokedToWallet(data)
                                    }
                                }
                            }
                            //creating self attested jwt credntials if requested is present in the self attested credetnials
                            //currently supports only passport
                            var (selfAttestedJwts, selfAttestedRecords): ([String]?,[SearchItems_CustomWalletRecordCertModel]?) = (nil,nil)
                            var credentialTypesRequested: [String]?
                            
                            if presentationDefinition == "" && dcqlQuery == nil {
                                UIApplicationUtils.hideLoader()
                                UIApplicationUtils.showErrorSnackbar(message: "error_invalid_qr_code".localize)
                                return
                            } else {
                                let jsonData = self.presentationDefinition.replacingOccurrences(of: "+", with: " ").data(using: .utf8)!
                                
                                var queryItem: Any?
                                if let dcqlQuery = dcqlQuery {
                                    queryItem = dcqlQuery
                                } else {
                                   
                                    let jsonObject2 = self.addTypeToJsonPath(data: jsonData, queryItem: presentationDefinition).0
                                    let updatedData = try? JSONSerialization.data(withJSONObject: jsonObject2)
                                    
                                    guard let presentationDefinitionModel1 = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: updatedData!) else { return  }
                                    self.presentationDefinitionModel = try JSONDecoder().decode(PresentationDefinitionModel.self, from: jsonData)
                                    queryItem = presentationDefinitionModel1
                                }
                                
                                if let (credentials, isLimitedDisclosure) = self.parseCredentialTypesRequested(queryItem: queryItem) {
                                    credentialTypesRequested = credentials
                                    (selfAttestedJwts, selfAttestedRecords) = await self.checkWalletForSelfAttestedCredentials(credentialTypesRequested: credentials ?? [], processingVPExchange: true, limitedDisclosure: isLimitedDisclosure, type: addTypeToJsonPath(data: jsonData, queryItem: queryItem).1)
                                }
                                
                                var credentialList: [String] = []
                                for credential in searchResponse?.records ?? []{
                                    if credential.value?.format == "mso_mdoc"{
                                        credentialList.append(credential.value?.EBSI_v2?.credentialJWT ?? "")
                                    } else if credential.value?.format != "mso_mdoc" {
                                        credentialList.append(credential.value?.EBSI_v2?.credentialJWT ?? "")
                                    }
                                }
                                
                                // Convert this credentialList to list of JWTs (JwtList)
                                
                                //adding the self attested jwt credentials to other openID credentials
                                if selfAttestedJwts != nil {
                                    for k in 0..<(selfAttestedJwts?.count ?? 0) {
                                        credentialList.append(selfAttestedJwts?[k] ?? "")
                                    }
                                }
                                
                                // Pass this JwtList to filterCredentials()
                                guard let queryData = queryItem else { return }
                                var filteredCredentialsIncludeRevoked: [[String]] = []
                                FilterCredentialService().filterCredentials(credentialList: credentialList, queryItems: queryData) { data in
                                    filteredCredentialsIncludeRevoked = data
                                    
                                    //verificationHandler?.filterCredentials(credentialList: credentialList, presentationDefinition: presentationDefinitionModel)
                                    
                                    let filteredCredentials = filteredCredentialsIncludeRevoked.map { list in
                                        list.filter { item in
                                            !revokedList.contains(item)
                                        }
                                    }
                                    var exchangeDataRecordModel =  [SearchItems_CustomWalletRecordCertModel]()
                                    let records =  searchResponse?.records
                                    // FIXME: convert this 'filteredCredentials' to [String: Any] (credentialsDict)
                                    var credentialsDict = [[String: Any]]()
                                    var dict = [String: Any]()
                                    var processedCredentials: [[String]] = []
                                    
                                    EBSIWallet.shared.exchangeDataRecordsdModel.removeAll()
                                    EBSIWallet.shared.exchangeCredentialRecordsdModel.removeAll()
                                    EBSIWallet.shared.pwaExchangeDataRecordsdModel.removeAll()
                                    self.pwaDataRecords.removeAll()
                                    processedCredentials.removeAll()
                                    
                                    //FIXME: for multple input descriptors, come and edit here
                                    
                                    if filteredCredentials != nil {
                                        
                                        for data in filteredCredentials {
                                            if data.isEmpty {
                                                UIApplicationUtils.hideLoader()
                                                UIApplicationUtils.showErrorSnackbar(message: "connection_insufficient_data_requested".localizedForSDK())
                                                return
                                            }
                                        }
                                        
                                        for list in filteredCredentials {
                                            let sortedCredential = getSortedCredentialsByIssuance(from: list)
                                            var exchangeDataRecordModel = records?.filter({ $0.value?.EBSI_v2?.credentialJWT == sortedCredential.first })
                                            var pwaExchangeDataRecordModel : [SearchItems_CustomWalletRecordCertModel]? = []
                                            //                                            if transactionData.isNotEmpty {
                                            for data in sortedCredential {
                                                let split = data.split(separator: ".")
                                                if split.count > 1,
                                                   let jsonString = "\(split[1])".decodeBase64(),
                                                   let jsonDict = UIApplicationUtils.shared.convertStringToDictionary(text: jsonString),
                                                   let vct = jsonDict["vct"] as? String {
                                                    if vct == "PaymentWalletAttestation" {
                                                        if let matchedCred = records?.filter({ $0.value?.EBSI_v2?.credentialJWT == data }) {
                                                            pwaExchangeDataRecordModel?.append(contentsOf: matchedCred)
                                                        }
                                                    }
                                                }
                                            }
                                            EBSIWallet.shared.exchangeCredentialRecordsdModel.removeAll()
                                            for data in sortedCredential {
                                                if let matchedCred = records?.filter({ $0.value?.EBSI_v2?.credentialJWT == data }) {
                                                    exchangeCredentialRecordsdModel.append(contentsOf: matchedCred)
                                                }
                                            }
                                            
                                            
                                            if let selfAttestedJwts = selfAttestedJwts {
                                                for data in sortedCredential {
                                                    for k in 0..<selfAttestedJwts.count {
                                                        if selfAttestedJwts[k] == data,
                                                           let updatedRecord = selfAttestedRecords?[k] {
                                                            let record = updatedRecord
                                                            if record.value?.photoIDCredential != nil {
                                                                //                                                            record.value = PhotoIDParser.shared.createPhotoIDWithResponse(photoIDCredential: record.value?.photoIDCredential, credentialJwt: selfAttestedJwts[k], connectionModel: connectionModel)
                                                                //                                                            exchangeCredentialRecordsdModel.append(record)
                                                                record.value?.EBSI_v2 = EBSI_V2_WalletModel(id: "", attributes: [], issuer: "", credentialJWT: selfAttestedJwts[k])
                                                                exchangeCredentialRecordsdModel.append(record)
                                                                
                                                            } else {
                                                                record.value?.EBSI_v2 = EBSI_V2_WalletModel(id: "", attributes: [], issuer: "", credentialJWT: selfAttestedJwts[k])
                                                                exchangeCredentialRecordsdModel.append(record)
                                                            }
                                                        }
                                                    }
                                                }
                                                let selfAttestedJwtsValue = selfAttestedJwts.first(where: { $0 == sortedCredential.first})
                                                let selfAttestedRecordData = selfAttestedRecords?.first(where: { $0.value?.EBSI_v2?.credentialJWT == sortedCredential.first})
                                                if let updatedRecord = selfAttestedRecordData {
                                                    let record = updatedRecord
                                                    record.value?.EBSI_v2 = EBSI_V2_WalletModel(id: "", attributes: [], issuer: "", credentialJWT: selfAttestedJwtsValue)
                                                    pwaDataRecords.append(record)
                                                }
                                            }
                                            let jwtArray = exchangeCredentialRecordsdModel.compactMap { $0.value?.EBSI_v2?.credentialJWT }
                                            
                                            let sortedJWTs = getSortedCredentialsByIssuance(from: jwtArray)
                                            
                                            let jwtToRecordMap: [String: SearchItems_CustomWalletRecordCertModel] = Dictionary(uniqueKeysWithValues:
                                                                                                                                exchangeCredentialRecordsdModel.compactMap {
                                                guard let jwt = $0.value?.EBSI_v2?.credentialJWT else { return nil }
                                                return (jwt, $0)
                                            }
                                            )
                                            
                                            let sortedExchangeCredentialRecordsdModel = sortedJWTs.compactMap { jwtToRecordMap[$0] }
                                            
                                            if let matchedCred = records?.filter({ $0.value?.EBSI_v2?.credentialJWT == sortedCredential.first }) {
                                                pwaDataRecords.append(contentsOf: matchedCred)
                                            }
                                            
                                            exchangeDataRecordsdModel.append(sortedExchangeCredentialRecordsdModel)
                                            EBSIWallet.shared.pwaExchangeDataRecordsdModel.append(contentsOf: pwaExchangeDataRecordModel ?? [])
                                            for item in sortedCredential {
                                                dict["noKey"] = item
                                                credentialsDict.append(dict)
                                            }
                                            
                                            processedCredentials.append(sortedCredential)
                                        }
                                        
                                    }
                                    debugPrint("### CredentialsJWT dict count:\(credentialsDict.count)")
                                    
                                    if credentialsDict.isEmpty {
                                        UIApplicationUtils.showErrorSnackbar(message: "No data available".localized())
                                        UIApplicationUtils.hideLoader()
                                    } else {
                                        
                                        Task { [credentialsDict] in
                                            
                                            connectionModel = await getEBSI_V3_connection(orgID: exchangeClientID) ?? CloudAgentConnectionWalletModel()
                                            if (connectionModel.value == nil) {
                                                connectionModel = await getEBSI_V3_connection() ?? CloudAgentConnectionWalletModel()
                                            }
                                            
                                            let dataAgreementContext = await DataAgreementUtil.shared.getDataAgreement()
                                            print("")
                                            debugPrint("###connectionModel name:\(connectionModel.value?.orgDetails?.name ?? "")")
                                            DispatchQueue.main.async {
                                                let allHaveFundingSource = EBSIWallet.shared.exchangeDataRecordsdModel.first?.allSatisfy { $0.value?.fundingSource != nil }
                                                if let transactionDataValue = self.transactionData.first, transactionDataValue.isNotEmpty {
                                                    let transactionDataBase64 = self.transactionData.first?.decodeBase64()
                                                    guard let transactionDataJson = transactionDataBase64?.data(using: .utf8) else { return }
                                                    let transactionDataModel = try? JSONDecoder().decode(eudiWalletOidcIos.TransactionData.self, from: transactionDataJson)
                                                    if (transactionDataModel?.type == "payment_data") || (transactionDataModel?.type == "payment_data" &&  allHaveFundingSource ?? false) {
                                                        if let credentialSet = self.dcqlQuery?.credentialSets {
                                                            if self.checkIfCredentialSetSupportedForPWA(dcql: self.dcqlQuery) && checkIfpwaIsMandatorySingle(input: self.exchangeDataRecordsdModel, dcql: dcqlQuery) && !hasDuplicatesOptionsInCredentiaSet(in: self.dcqlQuery){
                                                                let vc = PaymentDataConfirmationBottomSheetVC(nibName: "PaymentDataConfirmationBottomSheetVC", bundle: Bundle.module)
                                                                vc.modalPresentationStyle = .overFullScreen
                                                                vc.bottomSheetView.presentationDefinition =  self.presentationDefinition
                                                                vc.bottomSheetView.clientMetaData = self.clientMetaData
                                                                vc.bottomSheetView.credentialsDict = credentialsDict
                                                                vc.bottomSheetView.redirectUri = self.uri
                                                                vc.bottomSheetView.transactionDataBse64Data = self.transactionData
                                                                let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                                                                if let topVC = UIApplicationUtils.shared.getTopVC() {
                                                                    UIApplicationUtils.hideLoader()
                                                                    topVC.present(sheetVC, animated: false, completion: nil)
                                                                }
                                                            } else {
                                                                let vc = ExchangeDataPreviewBottomSheetVC(nibName: "ExchangeDataPreviewBottomSheetVC", bundle: Bundle.module)
                                                                vc.modalPresentationStyle = .overFullScreen
                                                                let credentialTypes = self.credentialOffer?.credentials?[0].types ?? []
                                                                let vct = self.getVctFromIssuerConfig(issuerConfig: self.openIdIssuerResponseData, type: credentialTypes.last ?? "")
                                                                var dataAgreement: DataAgreementContext? = nil
                                                                if credentialTypesRequested?.contains("passport") == true && vct == "PaymentWalletAttestation" {
                                                                    dataAgreement = dataAgreementContext
                                                                } else {
                                                                    dataAgreement = nil
                                                                }
                                                                vc.viewModel = ExchangeDataPreviewViewModel.init(walletHandle: walletHandler, connectionModel: self.connectionModel, conformance: "conformance")
                                                                vc.mode = .EBSIProcessingVPExchange
                                                                vc.redirectUri = self.uri
                                                                vc.presentationDefinition = self.presentationDefinition
                                                                vc.clientMetaData = self.clientMetaData
                                                                vc.dcqlQuery = self.dcqlQuery
                                                                vc.credentialsDict = credentialsDict
                                                                vc.filteredCredentials = processedCredentials
                                                                let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                                                                if let topVC = UIApplicationUtils.shared.getTopVC() {
                                                                    UIApplicationUtils.hideLoader()
                                                                    topVC.present(sheetVC, animated: false, completion: nil)
                                                                }
                                                                
                                                            }
                                                        } else {
                                                            
                                                            let vc = PaymentDataConfirmationBottomSheetVC(nibName: "PaymentDataConfirmationBottomSheetVC", bundle: Bundle.module)
                                                            vc.modalPresentationStyle = .overFullScreen
                                                            //vc.modalTransitionStyle = .crossDissolve
                                                            vc.bottomSheetView.presentationDefinition =  self.presentationDefinition
                                                            vc.bottomSheetView.clientMetaData = self.clientMetaData
                                                            vc.bottomSheetView.credentialsDict = credentialsDict
                                                            vc.bottomSheetView.redirectUri = self.uri
                                                            vc.bottomSheetView.transactionDataBse64Data = self.transactionData
                                                            let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                                                            if let topVC = UIApplicationUtils.shared.getTopVC() {
                                                                UIApplicationUtils.hideLoader()
                                                                topVC.present(sheetVC, animated: false, completion: nil)
                                                            }
                                                        }
                                                    } else if transactionDataModel?.type != "payment_data" {
                                                        let vc = ExchangeDataPreviewBottomSheetVC(nibName: "ExchangeDataPreviewBottomSheetVC", bundle: Bundle.module)
                                                        vc.modalPresentationStyle = .overFullScreen
                                                        let credentialTypes = self.credentialOffer?.credentials?[0].types ?? []
                                                        let vct = self.getVctFromIssuerConfig(issuerConfig: self.openIdIssuerResponseData, type: credentialTypes.last ?? "")
                                                        var dataAgreement: DataAgreementContext? = nil
                                                        if credentialTypesRequested?.contains("passport") == true && vct == "PaymentWalletAttestation" {
                                                            dataAgreement = dataAgreementContext
                                                        } else {
                                                            dataAgreement = nil
                                                        }
                                                        vc.viewModel = ExchangeDataPreviewViewModel.init(walletHandle: walletHandler, connectionModel: self.connectionModel, conformance: "conformance")
                                                        vc.mode = .EBSIProcessingVPExchange
                                                        vc.redirectUri = self.uri
                                                        vc.presentationDefinition = self.presentationDefinition
                                                        vc.clientMetaData = self.clientMetaData
                                                        vc.dcqlQuery = self.dcqlQuery
                                                        vc.credentialsDict = credentialsDict
                                                        vc.filteredCredentials = processedCredentials
                                                        let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                                                        if let topVC = UIApplicationUtils.shared.getTopVC() {
                                                            UIApplicationUtils.hideLoader()
                                                            topVC.present(sheetVC, animated: false, completion: nil)
                                                        }
                                                    }
                                                    else {
                                                        UIApplicationUtils.hideLoader()
                                                        UIApplicationUtils.showErrorSnackbar(message: "Currently not supported")
                                                    }
                                                } else {
                                                let vc = ExchangeDataPreviewBottomSheetVC(nibName: "ExchangeDataPreviewBottomSheetVC", bundle: Bundle.module)
                                                vc.modalPresentationStyle = .overFullScreen
                                                //vc.modalTransitionStyle = .crossDissolve
                                                let credentialTypes = self.credentialOffer?.credentials?[0].types ?? []
                                                let vct = self.getVctFromIssuerConfig(issuerConfig: self.openIdIssuerResponseData, type: credentialTypes.last ?? "")
                                                var dataAgreement: DataAgreementContext? = nil
                                                if selfAttestedJwts != nil && vct == "PaymentWalletAttestation" {
                                                    dataAgreement = dataAgreementContext
                                                } else {
                                                    dataAgreement = nil
                                                }
                                                vc.viewModel = ExchangeDataPreviewViewModel.init(walletHandle: walletHandler, connectionModel: self.connectionModel, conformance: "conformance")
                                                vc.mode = .EBSIProcessingVPExchange
                                                vc.redirectUri = self.uri
                                                vc.presentationDefinition = self.presentationDefinition
                                                vc.clientMetaData = self.clientMetaData
                                                vc.dcqlQuery = self.dcqlQuery
                                                vc.credentialsDict = credentialsDict
                                                vc.filteredCredentials = processedCredentials
                                                let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                                                if let topVC = UIApplicationUtils.shared.getTopVC() {
                                                    UIApplicationUtils.hideLoader()
                                                    topVC.present(sheetVC, animated: false, completion: nil)
                                                }
                                            }
                                                //                                            }
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
    
    
    public func checkIfCredentialSetSupportedForPWA(dcql: DCQLQuery?) -> Bool {
        EBSIWallet.shared.exchangeDataRecordsdModel
        var isSupported = true
        guard let dcql = dcql else { return isSupported }
        
        for set in dcql.credentialSets ?? [] {
            if set.options.count != 1 {
                isSupported = false
                return isSupported
            }
        }
        
        return isSupported
    }
    
    private func hasDuplicatesOptionsInCredentiaSet(in dcql: DCQLQuery?) -> Bool {
        var seen = Set<String>()
        
        for data in dcql?.credentialSets ?? [] {
            for option in data.options {
                for item in option {
                    if seen.contains(item) {
                        return true
                    }
                    seen.insert(item)
                }
            }
        }
        
        return false
    }
    
    func checkIfpwaIsMandatorySingle(input: [[SearchItems_CustomWalletRecordCertModel]], dcql: DCQLQuery?) -> Bool {
        for set in dcql?.credentialSets ?? [] {
            let required = set.required ?? true
            let options = set.options
            if options.count == 1 {
                for id in set.options[0] {
                    if let index = dcql?.credentials.firstIndex(where: { $0.id == id }),
                       input.indices.contains(index),
                       !input[index].isEmpty {
                        
                        
                        let items = input[index]
                        let isValid = items.contains { item in
                            item.value?.vct == "PaymentWalletAttestation"
                            
                        }
                        if required {
                            return isValid
                        }
                    }
                }
            }
        }
        return false
    }
    
    func getVctFromIssuerConfig(issuerConfig: IssuerWellKnownConfiguration?, type: String?) -> String? {
        guard let issuerConfig = issuerConfig else { return nil }
        
        if let credentialSupported = issuerConfig.credentialsSupported?.dataSharing?[type ?? ""] {
                return credentialSupported.vct
        } else {
            return nil
        }
    }
    
    func parseCredentialTypesRequested(compo: URLComponents? = nil, queryItem: Any? = nil) -> ([String]?, Bool)? {
        var credentialsRequested = [String]()
        var isSdJwt = false
        if let pd = queryItem as? PresentationDefinitionModel {
            
            guard let inputDescriptors = pd.inputDescriptors else {
                    print("No input descriptors found.")
                return (nil, false)
                }
                
            // Check limitDisclosure of the first input descriptor
                let firstInputDescriptor = inputDescriptors[0]
            if let constraints = firstInputDescriptor.constraints, constraints.limitDisclosure == nil{
                isSdJwt = false
            } else {
                isSdJwt = true
            }
                for inputDescriptor in inputDescriptors {
                    if let constraints = inputDescriptor.constraints, let fields = constraints.fields {
                        for field in fields {
                            
                                if let filter = field.filter {
                                    if let contains = filter.contains, contains.const == "Passport" {
                                        credentialsRequested.append("passport")
                                    } else if let pattern = filter.pattern, pattern.contains("Passport") {
                                        credentialsRequested.append("passport")
                                    } else if let contains = filter.contains, contains.pattern == "Passport"{
                                        credentialsRequested.append("passport")
                                    } else if filter.const == "Passport" {
                                        credentialsRequested.append("passport")
                                    }
                                }
                            
                            if let filter = field.filter {
                                if let contains = filter.contains, contains.const == "eu.europa.ec.eudi.photoid.1" {
                                    credentialsRequested.append("eu.europa.ec.eudi.photoid.1")
                                } else if let pattern = filter.pattern, pattern.contains("eu.europa.ec.eudi.photoid.1") {
                                    credentialsRequested.append("eu.europa.ec.eudi.photoid.1")
                                } else if let contains = filter.contains, contains.pattern == "eu.europa.ec.eudi.photoid.1"{
                                    credentialsRequested.append("eu.europa.ec.eudi.photoid.1")
                                } else if filter.const == "eu.europa.ec.eudi.photoid.1" {
                                    credentialsRequested.append("eu.europa.ec.eudi.photoid.1")
                                }
                            }
                            
                        }
                    }
                }
        } else if let dcql = queryItem as? DCQLQuery {
            let ff = dcql.credentials[0]
            let meta = ff.meta
            if case .dcSDJWT = meta {
                isSdJwt = true
            } else {
                isSdJwt = false
            }
            for item in dcql.credentials {
                let types = item.meta.extractedCredentialTypes.map { $0.lowercased() }
                
                credentialsRequested.append(contentsOf: types)
            }
            
        }
           

            debugPrint("###Credential types needed:\(credentialsRequested) ")
            return (credentialsRequested, isSdJwt)
        
    }
    
    func checkWalletForSelfAttestedCredentials(credentialTypesRequested: [String], processingVPExchange: Bool = false, limitedDisclosure: Bool = false, type: String?) async -> ([String]?,[SearchItems_CustomWalletRecordCertModel]?) {
        let certSearchModel = await WalletRecord.shared.fetchAllCert()
        
        if (credentialTypesRequested.contains("passport")) {
            guard let passport = certSearchModel?.records?.filter({ $0.value?.subType == "passport" }) else { return (nil,nil) }
            debugPrint(passport)
            if passport.count == 0 {
                return (nil,nil)
            }
            
            if limitedDisclosure {
                var passportJWTList: [String] = []
                for item in passport {
                    let passportJWT = await SelfAttestedToOpenID.shared.createOpenIDSDJWTForPassport(passportModel: (item.value?.passport)!, selectedDisclosures: credentialTypesRequested)
                    passportJWTList.append(passportJWT)
                }
                
                return (passportJWTList,passport)
            } else {
                var passportJWTList: [String] = []
                for item in passport {
                    let passportJWT = await SelfAttestedToOpenID.shared.createOpenIDJWTForPassport(passportModel: (item.value?.passport)!, type: type)
                    passportJWTList.append(passportJWT)
                }
                
                return (passportJWTList, passport)
            }
            
        } else {
            return (nil,nil)
        }
    }
    
    func credentialRequestAfterCertificateExchange() async {
        let privateKey = handlePrivateKey()
        guard let urlString = String(data: vpTokenResponseForConformanceFlow!, encoding: .utf8) else { return }
        let url = URL(string: urlString)!
        let did = await EBSIWallet.shared.createDIDKeyIdentifierForV3(privateKey: privateKey) ?? ""
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
            let accessTokenResponse = await EBSIWallet.shared.issueHandler?.processTokenRequest(did: EBSIWallet.shared.globalDID, tokenEndPoint: tokenEndpointForConformanceFlow ?? "", code: code, codeVerifier: EBSIWallet.shared.codeVerifierCreated, isPreAuthorisedCodeFlow: false, userPin: "", version: "", wua: "", pop: "", redirectURI: "openid://datawallet")
            if accessTokenResponse?.error != nil{
                DispatchQueue.main.async {
                    UIApplicationUtils.hideLoader()
                    UIApplicationUtils.showErrorSnackbar(message: accessTokenResponse?.error?.message ?? "Unexpected error. Please try again.".localized())
                }
            } else {
                await requestCredentialUsingEbsiV3(didKeyIdentifier: did, c_nonce: accessTokenResponse?.cNonce ?? "", accessToken: accessTokenResponse?.accessToken ?? "", privateKey: privateKey, ebsiV3Exchange: true, refreshToken: accessTokenResponse?.refreshToken ?? "")
            }
        } else {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let error = components.queryItems?.first(where: { $0.name == "error_description" })?.value {
                let message = error.replacingOccurrences(of: "+", with: " ")
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showErrorSnackbar(message: message)
            }
        }
    }

    
}
