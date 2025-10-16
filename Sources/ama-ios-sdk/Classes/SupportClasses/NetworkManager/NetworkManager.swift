//
//  NetworkManager.swift
//  Alamofire
//
//  Created by Mohamed Rebin on 15/11/20.
//

import Foundation
import Moya
import SVProgressHUD
import Alamofire

class NetworkManager {
    let provider = MoyaProvider<MyService>()
    public static let shared = NetworkManager()
    var baseURL = "https://mediator.igrant.io" //mediator.igrant.io
    var mediatorEndPoint = "https://mediator.igrant.io" //mediator.igrant.io

    private init() {
        provider.session.session.configuration.timeoutIntervalForRequest = 60
        provider.session.session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    }

    func getAgentConfig(completion: @escaping((AgentConfigurationResponse?) -> Void)){
        provider.request(.agentConfig) { (result) in
            switch result {
                case let .success(moyaResponse):
                    if moyaResponse.statusCode != 200 {
                        //UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
                       UIApplicationUtils.hideLoader()
                        completion(nil)
                    }
                    let data = moyaResponse.data // Data, your JSON response is probably in here!
                    let agentConfigurationResponse = try? JSONDecoder().decode(AgentConfigurationResponse.self, from: data)
                    completion(agentConfigurationResponse)
                case let .failure(error):
                        print(error.localizedDescription)
                    self.showError(error: error)
                    //                        if error._code == NSURLErrorTimedOut {
//
//                        }
                        completion(nil)
                    // TODO: handle the error == best. comment. ever.
                }
        }
    }
    
    func getRegistryInvitation() async -> AgentConfigurationResponse? {
        return await withCheckedContinuation { continuation in
            provider.request(.getRegistryInvitation) { (result) in
                switch result {
                case let .success(moyaResponse):
                    if moyaResponse.statusCode != 200 {
                        //UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
                        UIApplicationUtils.hideLoader()
                        continuation.resume(returning: nil)
                    }
                    let data = moyaResponse.data // Data, your JSON response is probably in here!
                    let agentConfigurationResponse = try? JSONDecoder().decode(AgentConfigurationResponse.self, from: data)
                    continuation.resume(returning: agentConfigurationResponse)
                case let .failure(error):
                    print(error.localizedDescription)
                    self.showError(error: error)
                    //                        if error._code == NSURLErrorTimedOut {
                    //
                    //                        }
                    continuation.resume(returning: nil)
                    // TODO: handle the error == best. comment. ever.
                }
            }
        }
    }
    
    @available(*, renamed: "sendMsg(isMediator:msgData:url:)")
    func sendMsg(isMediator: Bool,msgData:Data,url: String? = nil,completion: @escaping((Int,Data?) -> Void)){
        provider.request(.sendMessage(toMediator: isMediator,msgData: msgData,url: url)) { (result) in
            switch result {
                case let .success(moyaResponse):
//                    print(moyaResponse.request)
//                    print(moyaResponse.statusCode)
                    if moyaResponse.statusCode != 200 {
//                        UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
//                       UIApplicationUtils.hideLoader()
                        completion(0,nil)
                        return
                    } else {
                        let data = moyaResponse.data // Data, your JSON response is probably in here!
                        completion(moyaResponse.statusCode,data)
                    }
                case let .failure(error):
                    self.showError(error: error)
                    debugPrint(error.localizedDescription)
                    completion(0,nil)
                    // TODO: handle the error == best. comment. ever.
                }
        }
    }
    
    func sendMsg(isMediator: Bool,msgData:Data,url: String? = nil) async -> (Int, Data?) {
        return await withCheckedContinuation { continuation in
            sendMsg(isMediator: isMediator, msgData: msgData, url: url) { result1, result2 in
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    @available(*, renamed: "EBSI_sendMsg(param:url:JWT:contentType:)")
    func EBSI_sendMsg(param: [String : Any], url: String,JWT: String?, contentType: String? = "application/json", conformance: String? = nil, completion: @escaping((Int,Data?) -> Void)){
        provider.request(.EBSI(param: param, url: url, JWT: JWT, contentType: contentType, conformance: conformance)) { (result) in
            switch result {
                case let .success(moyaResponse):
//                    if moyaResponse.statusCode != 200 {
//                        UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
//                       UIApplicationUtils.hideLoader()
//                        completion(moyaResponse.statusCode,moyaResponse.data)
//                    }
                debugPrint(moyaResponse.request)
//                    print(moyaResponse.statusCode)
                    let data = moyaResponse.data // Data, your JSON response is probably in here!
                    completion(moyaResponse.statusCode,data)
                case let .failure(error):
//                    self.showError(error: error)
                debugPrint(error.localizedDescription)
                    completion(0,nil)
                    // TODO: handle the error == best. comment. ever.
                }
        }
    }
    
    func EBSI_sendMsg(param: [String : Any], url: String,accessToken: String?, contentType: String? = "application/json",conformance: String? = nil) async -> (Int, Data?) {
        return await withCheckedContinuation { continuation in
            EBSI_sendMsg(param: param, url: url, JWT: accessToken, contentType: contentType, conformance: conformance) { result1, result2 in
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    func polling(msgData:Data,completion: @escaping((Int,Data?) -> Void)){
        provider.request(.polling(msgData: msgData)) { (result) in
            switch result {
                case let .success(moyaResponse):
                    if moyaResponse.statusCode != 200 {
                        //UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
                       UIApplicationUtils.hideLoader()
                        completion(moyaResponse.statusCode,nil)
                    } else {
                        let data = moyaResponse.data // Data, your JSON response is probably in here!
                        completion(moyaResponse.statusCode,data)
                    }
//                    print(moyaResponse.request)
//                    print(moyaResponse.statusCode)
                    
                case let .failure(error):
//                    self.showError(error: error)
                    print(error.localizedDescription)
                    completion(0,nil)
                    // TODO: handle the error == best. comment. ever.
                }
        }
    }
    
    func mediator(param:[String:Any],completion: @escaping((Data?) -> Void)){
        provider.request(.mediator(param: param)) { (result) in
            switch result {
                case let .success(moyaResponse):
                    if moyaResponse.statusCode != 200 {
                        //UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
                       UIApplicationUtils.hideLoader()
                        completion(nil)
                    }else{
                        let data = moyaResponse.data // Data, your JSON response is probably in here!
                        completion(data)
                    }
                case let .failure(error):
                    self.showError(error: error)
                    print(error.localizedDescription)
                        completion(nil)
                    // TODO: handle the error == best. comment. ever.
                }
        }
    }
    
    @available(*, renamed: "get(service:)")
    func get(service: MyService, completion: @escaping((Data?)) -> Void) {
        provider.request(service){ (result) in
            switch result {
                case let .success(moyaResponse):
                if moyaResponse.statusCode != 200 {
                       //UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
                       UIApplicationUtils.hideLoader()
                        completion(Data())
                }else{
                    let data = moyaResponse.data // Data, your JSON response is probably in here!
                    completion(data)
                }
                case let .failure(error):
//                    self.showError(error: error)
                    print(error.localizedDescription)
                        completion(Data())
                    // TODO: handle the error == best. comment. ever.
                }
        }
    }
    
    func get(service: MyService) async -> (Data?) {
        return await withCheckedContinuation { continuation in
            get(service: service) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    
    
    @available(*, renamed: "EBSI_V2_authorize(url:)")
    func EBSI_V2_authorize(url: String, conformance: String? = nil, completion: @escaping((String?)) -> Void) async{
        let result = await EBSI_V2_authorize(url: url, conformance: conformance)
            completion(result)
    }
    
    
    @available(*, renamed: "EBSI_V2_authorize(url:)")
    func EBSI_V2_authorize(url: String, conformance: String? = nil) async -> (String?) {
        return await withCheckedContinuation { continuation in
            provider.request(.EBSI_V2_authorize_url(url: url, conformance: conformance)){ (result) in
                switch result {
                case let .success(moyaResponse):
                    if moyaResponse.statusCode != 302 {
                        //UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
                        UIApplicationUtils.hideLoader()
                        continuation.resume(returning: "")
                        return
                    }
                    let data = moyaResponse.response?.headers // Data, your JSON response is probably in here!
                    continuation.resume(returning: "")
                case let .failure(error):
                    //                    self.showError(error: error)
                    debugPrint(error.failureReason)
                    debugPrint(error.localizedDescription)
                    if let msg = ((error.errorUserInfo["NSUnderlyingError"] as? AFError)?.underlyingError as? NSError)?.userInfo["NSErrorFailingURLStringKey"] as? String{
                        continuation.resume(returning: msg)
                    } else {
                        continuation.resume(returning: "")
                    }
                   
                    // TODO: handle the error == best. comment. ever.
                }
            }
        }
    }
    
    func EBSI_V2_authentication_requests(url: String, conformance: String? = nil) async -> (Data?) {
        return await withCheckedContinuation { continuation in
            provider.request(.EBSI_V2_authentication_requests(url: url, conformance: conformance)){ (result) in
                switch result {
                case let .success(moyaResponse):
                    if moyaResponse.statusCode != 200 {
                        //UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
                        UIApplicationUtils.hideLoader()
                        continuation.resume(returning: nil)
                        return
                    }
                    let data = moyaResponse.data // Data, your JSON response is probably in here!
                    continuation.resume(returning: data)
                case let .failure(error):
                    //                    self.showError(error: error)
                    debugPrint(error.failureReason)
                    debugPrint(error.localizedDescription)
                    if let msg = ((error.errorUserInfo["NSUnderlyingError"] as? AFError)?.underlyingError as? NSError)?.userInfo["NSErrorFailingURLStringKey"] as? String{
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(returning: nil)
                    }
                   
                    // TODO: handle the error == best. comment. ever.
                }
            }
        }
    }
    
    func EBSI_V2_verify(url: String, param: [String: Any], conformance: String? = nil) async -> (Data?) {
        return await withCheckedContinuation { continuation in
            provider.request(.EBSI_V2_verify(url: url, param: param, conformance: conformance)){ (result) in
                switch result {
                case let .success(moyaResponse):
                    if moyaResponse.statusCode != 200 {
                        //UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
                        UIApplicationUtils.hideLoader()
                        continuation.resume(returning: nil)
                        return
                    }
                    let data = moyaResponse.data // Data, your JSON response is probably in here!
                    continuation.resume(returning: data)
                case let .failure(error):
                    debugPrint(error.localizedDescription)
                    if let msg = ((error.errorUserInfo["NSUnderlyingError"] as? AFError)?.underlyingError as? NSError)?.userInfo["NSErrorFailingURLStringKey"] as? String{
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(returning: nil)
                    }
                   
                    // TODO: handle the error == best. comment. ever.
                }
            }
        }
    }
    
    
    
    func showError(error: MoyaError){
        UIApplicationUtils.showErrorSnackbar(message: "Unexpected error. Please try again.".localizedForSDK())
       UIApplicationUtils.hideLoader()
        print("Taking longer than expected. Please try again ?")
    }
}
