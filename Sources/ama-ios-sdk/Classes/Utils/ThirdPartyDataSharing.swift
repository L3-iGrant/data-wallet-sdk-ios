//
//  ThirdPartyDataSharingUtils.swift
//  ama-ios-sdk
//
//  Created by iGrant on 23/01/25.
//

import Foundation
import IndyCWrapper

public class ThirdPartyDataSharing {
    public static let shared = ThirdPartyDataSharing()
    public init() {}
    
    private func fetchPreferences(connectionModel: CloudAgentConnectionWalletModel?) async -> [ThirdPartyPreferenceModel]?{
        var responseDataArray: [ThirdPartyPreferenceModel] = []
        guard let connModel = connectionModel else { return nil}
        if let connModel = connectionModel, let model = await ThirdPartySharingProtocols.fetchPreferences(connectionModel: connModel){
            if let data = model.prefs?.group(by: { $0.sector }) {
                for (mainIndex, values) in data.enumerated() {
                    let dus = values.value.compactMap({ $0.dus })
                    if dus.isNotEmpty {
                        var combine: [ThirdPartyDus] = []
                        combine = Array(dus.joined())
                        for i in 0..<combine.count {
                            combine[i].sector = values.key
                            combine[i].daInstanceID = values.value[mainIndex].instanceID
                        }
                        let id = values.value[mainIndex].instanceID
                        let dataAgreement = await WalletFetchUtils.getDataAgreementContextFromInstanceId(id: id ?? "")
                        let model = ThirdPartyPreferenceModel(name: values.key, purpose: dataAgreement?.message?.body?.purpose ?? "", id: id, toggleStatus: (values.value[mainIndex].instancePermissionState ?? .disallow) == .allow,dataAgreement: dataAgreement, value: combine)
                        responseDataArray.append(model)
                    }
                }
            }
            UIApplicationUtils.hideLoader()
            return responseDataArray
        }
        return nil
    }
    
    public func fetchPreferencesUsingOrgID(orgID: String) async -> [ThirdPartyPreferenceModel]? {
        do {
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithOrgId,searchValue: orgID)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            guard let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) else { return nil }
            let records = messageModel["records"] as? [[String:Any]]
            guard let firstRecord = records?.first as NSDictionary? else {return nil }
            let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord) as? CloudAgentConnectionWalletModel
            guard let responseDataArray = await fetchPreferences(connectionModel: connectionModel) else { return nil}
            UIApplicationUtils.hideLoader()
            return responseDataArray
        } catch {
            return nil
        }
    }
    
    public func fetchPreferencesUsingDID(did: String) async -> [ThirdPartyPreferenceModel]? {
        do {
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchtWithDidKey,searchValue: did)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            guard let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) else { return nil }
            let records = messageModel["records"] as? [[String:Any]]
            guard let firstRecord = records?.first as NSDictionary? else {return nil }
            let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord) as? CloudAgentConnectionWalletModel
            guard let responseDataArray = await fetchPreferences(connectionModel: connectionModel) else { return nil}
            UIApplicationUtils.hideLoader()
            return responseDataArray
        } catch {
            return nil
        }
    }
    
    private func updateDDAPreference(connectionModel: CloudAgentConnectionWalletModel?, data: ThirdPartyDus?) async ->  ( Bool?, ThirdPartyDus?) {
        guard var data = data else { return (false, nil)}
        guard let connectionModel = connectionModel else { return (false, nil)}
        let now = data.ddaInstancePermissionState
        let newState = (now == .allow) ? PermissionState.disallow : PermissionState.allow
        let update = await ThirdPartySharingProtocols.updatePreferences(
            connectionModel: connectionModel,
            ddaInstanceId: data.ddaInstanceID ?? "",
            daInstanceId: data.daInstanceID ?? "",
            state: (now == .allow) ? PermissionState.disallow.rawValue : PermissionState.allow.rawValue
        )
        data.ddaInstancePermissionState = now == .allow ? .disallow : .allow
        if !update {
            data.ddaInstancePermissionState = (data.ddaInstancePermissionState == .allow) ? .disallow : .allow
        }
        return (true, data)
    }
    
    public func updateDDAPreferenceUsingOrgID(orgID: String, data: ThirdPartyDus?) async -> ( Bool?, ThirdPartyDus?) {
        do {
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithOrgId,searchValue: orgID)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            guard let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) else { return (false, nil) }
            let records = messageModel["records"] as? [[String:Any]]
            guard let firstRecord = records?.first as NSDictionary? else {return (false, nil) }
            let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord) as? CloudAgentConnectionWalletModel
            let result = await updateDDAPreference(connectionModel: connectionModel, data: data)
            return result
        } catch {
            return (nil, nil)
        }
    }
    
    public func updateDDAPreferenceUsingDID(did: String, data: ThirdPartyDus?) async -> ( Bool?, ThirdPartyDus?) {
        do {
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchtWithDidKey,searchValue: did)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            guard let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) else { return (false, nil) }
            let records = messageModel["records"] as? [[String:Any]]
            guard let firstRecord = records?.first as NSDictionary? else {return (false, nil) }
            let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord) as? CloudAgentConnectionWalletModel
            let result = await updateDDAPreference(connectionModel: connectionModel, data: data)
            return result
        } catch {
            return (nil, nil)
        }
    }
    
    private func updateDAPreference(responseData: ThirdPartyPreferenceModel?, connectionModel: CloudAgentConnectionWalletModel?) async -> (Bool?, ThirdPartyPreferenceModel?) {
        guard var item = responseData else { return (false, nil)}
        guard let connModel = connectionModel else { return (false, nil)}
        let update = await ThirdPartySharingProtocols.updateAgreementLevel(connectionModel: connModel, instanceId: item.id ?? "", state: item.toggleStatus ? PermissionState.disallow.rawValue : PermissionState.allow.rawValue)
        let now = item.toggleStatus
        item.toggleStatus = !now
        if !update {
            let currentStatus = item.toggleStatus
            item.toggleStatus = !currentStatus
        }
        return (true, item)
    }
    
    public func updateDAPreferenceUsingOrgID(responseData: ThirdPartyPreferenceModel?, orgID: String) async -> (Bool?, ThirdPartyPreferenceModel?) {
        do {
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithOrgId,searchValue: orgID)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            guard let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) else { return (false, nil) }
            let records = messageModel["records"] as? [[String:Any]]
            guard let firstRecord = records?.first as NSDictionary? else {return (false, nil) }
            let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord) as? CloudAgentConnectionWalletModel
            let result = await updateDAPreference(responseData: responseData, connectionModel: connectionModel)
            return result
        } catch {
            return (nil, nil)
        }
    }
    
    public func updateDAPreferenceUsingDID(responseData: ThirdPartyPreferenceModel?, did: String) async -> (Bool?, ThirdPartyPreferenceModel?) {
        do {
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchtWithDidKey,searchValue: did)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            guard let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) else { return (false, nil) }
            let records = messageModel["records"] as? [[String:Any]]
            guard let firstRecord = records?.first as NSDictionary? else {return (false, nil) }
            let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord) as? CloudAgentConnectionWalletModel
            let result = await updateDAPreference(responseData: responseData, connectionModel: connectionModel)
            return result
        } catch {
            return (nil, nil)
        }
    }
    
}
