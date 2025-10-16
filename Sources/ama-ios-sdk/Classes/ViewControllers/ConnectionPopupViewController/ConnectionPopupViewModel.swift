//
//  ConnectionPopupViewModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 19/12/20.
//

import Foundation
import IndyCWrapper

protocol ConnectionPopupViewModelDelegate: class{
    func connectionEstablised(connModel:CloudAgentConnectionWalletModel, recipientKey: String, myVerKey: String)
    func dismissPopup()
    func tappedOnConnect()
}

struct ConnectionPopupViewModel {
    var orgName: String?
    var orgImageURL: String?
    var walletHandler: IndyHandle?
    var recipientKey: String?
    var serviceEndPoint: String?
    var routingKey: [String]?
    var pollingEnabled: Bool!
    var orgId: String?
    var orgDetails: OrganisationInfoModel?
    weak var delegate:ConnectionPopupViewModelDelegate?
    var didCom: String?
    
    init(orgName: String?,orgImageURL: String?,walletHandler: IndyHandle?,recipientKey: String?,serviceEndPoint: String?,routingKey: [String]?, pollingEnabled: Bool? = false, orgId: String?, orgDetails: OrganisationInfoModel?,didCom: String) {
        self.orgName = orgName
        self.orgImageURL = orgImageURL
        self.walletHandler = walletHandler
        self.recipientKey = recipientKey
        self.serviceEndPoint = serviceEndPoint
        self.routingKey  = routingKey
        self.pollingEnabled = pollingEnabled ?? true
        self.orgId = orgId
        self.orgDetails = orgDetails
        self.didCom = didCom
        
    }
    //(walletHandler: IndyHandle, label: String, theirVerKey: String,serviceEndPoint: String, routingKey: String, imageURL: String,mediatorVerKey: String,pollingEnabled: Bool = true,completion: @escaping(Bool) -> Void)
    
    func startConnection(){
        AriesCloudAgentHelper.shared.newConnectionConfigCloudAgent(walletHandler: self.walletHandler ?? IndyHandle(), label: self.orgName ?? "", theirVerKey: self.recipientKey ?? "", serviceEndPoint: self.serviceEndPoint ?? "", routingKey: self.routingKey, imageURL: self.orgImageURL ?? "", pollingEnabled: self.pollingEnabled,orgId: self.orgId,orgDetails: self.orgDetails,didCom: self.didCom ?? "") { (connectionModel,recipientKey,myVerKey)  in
            if let connectionModel = connectionModel, let recipientKey = recipientKey, let myVerKey = myVerKey {
                delegate?.connectionEstablised(connModel:connectionModel, recipientKey: recipientKey, myVerKey: myVerKey)
            } else {
                delegate?.dismissPopup()
            }
            
        }
    }
    
    func EBSI_V2_connection_configure() async{
        do{
            let did = EBSIWallet.shared.createV2DID()
            let label = "EBSI"
            let imageURL = "https://i.ibb.co/jwPYjLb/Screenshot-2022-06-29-152618.png"
            var orgDetail = OrganisationInfoModel.init()
            orgDetail.orgId = orgId
            orgDetail.logoImageURL = imageURL
            orgDetail.location = "European Union"
            orgDetail.organisationInfoModelDescription = "EBSI is a joint initiative from the European Commission and the European Blockchain Partnership. The vision is to leverage blockchain to accelerate the creation of cross-border services for public administrations and their ecosystems to verify information and to make services more trustworthy."
            orgDetail.name = "EBSI"
            let (_, connID) = try await WalletRecord.shared.add(invitationKey: "", label: label, serviceEndPoint: "", connectionRecordId: "",imageURL: imageURL, walletHandler: self.walletHandler ?? IndyHandle(),type: .connection, orgID: orgId)
            let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: self.walletHandler ?? IndyHandle(),recipientKey: "",label: label, type: UpdateWalletType.trusted, id: connID, theirDid: "", myDid: did,imageURL: imageURL,invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: orgDetail, orgID:orgId)
            _ = try await
            AriesAgentFunctions.shared.updateWalletTags(walletHandler: self.walletHandler ?? IndyHandle(), id: connID, myDid: did, type: .cloudAgentActive, orgID: orgId)
            guard let connectionModel = await EBSIWallet.shared.getEBSI_V2_connection() else {
                DispatchQueue.main.async {
                    delegate?.dismissPopup()
                }
                return
            }
            DispatchQueue.main.async {
                delegate?.connectionEstablised(connModel: connectionModel, recipientKey: "", myVerKey: "")
            }
        } catch {
            debugPrint(error.localizedDescription)
            DispatchQueue.main.async {
                delegate?.dismissPopup()
            }
        }
    }
    func cancelled(){
        
    }
}
