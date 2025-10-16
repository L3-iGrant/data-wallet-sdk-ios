//
//  Alamofire
//
//  Created by Mohamed Rebin on 15/11/20.
//

import Foundation
import Moya

enum MyService {
    case agentConfig
    case sendMessage(toMediator:Bool,msgData: Data,url: String?)
    case mediator(param: [String: Any])
    case connectionRequestToCloudAgent(param: [String: Any])
    case getGenesis
    case QRCode(url: String?)
    case polling(msgData: Data)
    case getDataWalletMetaData
    case getPKPassBoardingMetaData
    case getBlinksMetaData
    case getMyDataProfileMetaData
    case getRegistryInvitation
    case EBSI(param: [String: Any],url: String?,JWT: String?, contentType: String?, conformance: String?)
    case EBSI_V2_initiate_issuance
    case EBSI_V2_authorize_url(url: String?,conformance: String?)
    case EBSI_V2_authentication_requests(url: String?,conformance: String?)
    case EBSI_V2_verify(url: String?,param: [String: Any], conformance: String?)
    case getProcessedFirebaseDynamicLink(challenge: String, link: String)
    case getDataAgreements(dataAgreementID: String, apiKey: String, orgID: String)
}

// MARK: - TargetType Protocol Implementation
extension MyService: TargetType {
    
    //    https://mediator.igrant.io/.well-known/agent-configuration
    var baseURL: URL {
        switch self {
        case .connectionRequestToCloudAgent:
            return URL(string: NetworkManager.shared.baseURL) ?? URL(string: "https://mediator.igrant.io")!
        case .sendMessage(toMediator: let isMediator, msgData: _, let url):
            return isMediator ? URL(string: "https://mediator.igrant.io")! : (URL(string: url ?? "") ?? URL(string: NetworkManager.shared.baseURL) ?? URL(string: "https://mediator.igrant.io")!)
        case .getGenesis:
            return URL(string: "https://raw.githubusercontent.com/L3-iGrant/datawallet-metadata/main/ledgers.json")!
        case .getDataWalletMetaData:
            return URL(string: "https://raw.githubusercontent.com/L3-iGrant/datawallet-metadata/main/last_updated.json")!
        case .getBlinksMetaData:
            return URL(string: "https://raw.githubusercontent.com/L3-iGrant/datawallet-metadata/main/blinks.json")!
        case .getPKPassBoardingMetaData:
            return URL(string: "https://raw.githubusercontent.com/L3-iGrant/datawallet-metadata/main/pkpass_boarding_pass.json")!
        case .getMyDataProfileMetaData:
            return URL(string: "https://raw.githubusercontent.com/L3-iGrant/datawallet-metadata/main/mydata_profile_schema.json")!
        case .QRCode(let url):
            return URL(string: url ?? "") ?? URL(string: "https://mediator.igrant.io")!
        case .polling:
            return URL(string: NetworkManager.shared.mediatorEndPoint)!
        case .getRegistryInvitation:
            return URL(string: "https://cloudagent-demo.igrant.io/v1/mydata-did-registry/admin/.well-known/did-configuration.json")!
        case .EBSI(param: _, url: let url, JWT: _, contentType: _, conformance: _):
            return URL(string: url ?? "")!
        case .EBSI_V2_initiate_issuance:
            return URL(string: EBSIWallet.baseURL_V2)!
        case .EBSI_V2_authorize_url(let url, _), .EBSI_V2_authentication_requests(let url, _):
            return URL(string: url ?? "") ?? URL(string: EBSIWallet.baseURL_V2)!
        case .EBSI_V2_verify(url: let url, _, _):
            return URL(string: url ?? "") ?? URL(string: EBSIWallet.baseURL_V2)!
        case .getProcessedFirebaseDynamicLink:
            return URL(string: "https://staging-api.igrant.io/v1/data-wallet")!
        case .getDataAgreements(dataAgreementID: _, apiKey: _, let orgId):
            return URL(string: "https://cloudagent.igrant.io/v1/\(orgId)/admin/v1")!
        default:
            return URL(string: NetworkManager.shared.mediatorEndPoint)!
        }
    }
    
    var path: String {
        switch self {
        case .agentConfig,.mediator(param: _):
            return ""//.well-known/agent-configuration"
        case .connectionRequestToCloudAgent(param: _), .getRegistryInvitation:
            return ""
        case .sendMessage(toMediator: _, msgData: _,url: _):
            return "" //toMediator ? "/.well-known/agent-configuration" : ""
        case .getGenesis,.getDataWalletMetaData,.getPKPassBoardingMetaData,.getBlinksMetaData,.getMyDataProfileMetaData:
            return ""
        case .QRCode:
            return ""
        case .polling:
            return "" //.well-known/agent-configuration"
        case .EBSI:
            return ""
        case .EBSI_V2_initiate_issuance:
            return "/conformance/v2/issuer-mock/initiate"
        case .EBSI_V2_authorize_url, .EBSI_V2_verify,.EBSI_V2_authentication_requests:
            return ""
        case .getProcessedFirebaseDynamicLink:
            return "/firebase-dynamic-link"
        case .getDataAgreements:
            return "/data-agreements"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .agentConfig,.getGenesis,.getPKPassBoardingMetaData,.getDataWalletMetaData, .getRegistryInvitation, .getBlinksMetaData,.getMyDataProfileMetaData,.getProcessedFirebaseDynamicLink,.getDataAgreements:
            return .get
        case .sendMessage,.mediator:
            return .post
        case .connectionRequestToCloudAgent:
            return .post
        case .QRCode:
            return .post
        case .polling:
            return .post
        case .EBSI:
            return .post
        case .EBSI_V2_initiate_issuance,.EBSI_V2_authorize_url,.EBSI_V2_authentication_requests:
            return .get
        case .EBSI_V2_verify:
            return .post
        }
    }
    var task: Task {
        switch self {
        case .agentConfig,.getGenesis,.QRCode, .getPKPassBoardingMetaData,.getDataWalletMetaData, .getRegistryInvitation, .getBlinksMetaData,.getMyDataProfileMetaData:
            // Send no parameters
            return .requestPlain
        case let.sendMessage(_,msgData,_):
            return .requestData(msgData)
        case let .mediator(param: param):
            return .requestParameters(parameters: param, encoding: JSONEncoding.default)
        case .connectionRequestToCloudAgent(param: let param):
            return .requestParameters(parameters: param, encoding: JSONEncoding.default)
        case .polling(msgData: let data):
            return .requestData(data)
        case .EBSI(param: let param, url: _,JWT: _, contentType: let contentType, _):
            if contentType == "application/json" {
                return .requestParameters(parameters: param, encoding: JSONEncoding.default)
            } else {
                //URLEncoding.httpBody
                return .requestParameters(parameters: param, encoding: URLEncoding.httpBody)
            }
        case .EBSI_V2_initiate_issuance:
            return .requestPlain
        case .EBSI_V2_authorize_url,.EBSI_V2_authentication_requests:
            return .requestPlain
        case .EBSI_V2_verify(url: _, param: let param, conformance: _):
            return .requestParameters(parameters: param, encoding: URLEncoding.httpBody)
        case .getProcessedFirebaseDynamicLink(challenge: let challenge, link: let link):
            let parameters: [String: Any] = [
                "challenge": challenge,
                "link": link
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        case let .getDataAgreements(dataAgreementID, apiKey, orgId):
            let parameters: [String: Any] = [
                "data_agreement_id": dataAgreementID,
                "publish_flag": true
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
            
        }
    }
    var sampleData: Data {
        return "".utf8Encoded
        //        switch self {
        //        case .agentConfig:
        //            return "".utf8Encoded
        //        case .showUser(let id):
        //            return "{\"id\": \(id), \"first_name\": \"Harry\", \"last_name\": \"Potter\"}".utf8Encoded
        //        case .createUser(let firstName, let lastName):
        //            return "{\"id\": 100, \"first_name\": \"\(firstName)\", \"last_name\": \"\(lastName)\"}".utf8Encoded
        //        case .updateUser(let id, let firstName, let lastName):
        //            return "{\"id\": \(id), \"first_name\": \"\(firstName)\", \"last_name\": \"\(lastName)\"}".utf8Encoded
        //        case .showAccounts:
        //            // Provided you have a file named accounts.json in your bundle.
        //            guard let url = Bundle.main.url(forResource: "accounts", withExtension: "json"),
        //                let data = try? Data(contentsOf: url) else {
        //                    return Data()
        //            }
        //            return data
        //        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .agentConfig,.mediator,.connectionRequestToCloudAgent, .getGenesis, .getPKPassBoardingMetaData,.getDataWalletMetaData, .getRegistryInvitation, .getBlinksMetaData,.getMyDataProfileMetaData,.getProcessedFirebaseDynamicLink: // Send no parameters
            return ["Content-type": "application/json"]
        case .sendMessage:
            return ["Content-Type": "application/ssi-agent-wire"]
        case .QRCode:
            return nil
        case .polling:
            return ["Content-Type": "application/ssi-agent-wire"]
        case .EBSI(param: _, url: _,JWT: let JWT, contentType: let contentType, let conformance):
            return ["Content-type":contentType ?? "application/json", "Authorization" : "Bearer \(JWT ?? "")", "Conformance": conformance ?? NSUUID().uuidString.lowercased()]
        case .EBSI_V2_initiate_issuance:
            return ["Content-type": "application/json"]
        case .EBSI_V2_authorize_url(url: _, conformance: let conformance),.EBSI_V2_authentication_requests(url: _, conformance: let conformance):
            return ["Content-type": "application/json", "Conformance": conformance ?? NSUUID().uuidString.lowercased()]
        case .EBSI_V2_verify(url: _, param: _, conformance: let conformance):
            return ["Content-type": "application/x-www-form-urlencoded", "Conformance": conformance ?? NSUUID().uuidString.lowercased()]
        case let .getDataAgreements(dataAgreementID, apiKey, orgId):
            return [
                "Accept": "application/json",
                "Authorization": "ApiKey \(apiKey)"
            ]
        }
    }
}

// MARK: - Helpers
extension String {
    var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
    
    var utf8Encoded: Data {
        return data(using: .utf8)!
    }
}
