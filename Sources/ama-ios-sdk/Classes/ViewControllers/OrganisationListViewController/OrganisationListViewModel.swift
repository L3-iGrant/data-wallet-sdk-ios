//
//  OrganisationListViewModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 07/12/20.
//

import Foundation
import IndyCWrapper

protocol OrganisationListDelegate: AnyObject {
    func reloadData()
    func tableAction(_ index: Int)
}


enum ConnectionType: Int {
    case All
    case Organisations
    case People
    case Devices
}

class OrganisationListViewModel {
    var walletHandle: IndyHandle?
    var connections: [CloudAgentConnectionWalletModel]?
    var connectionHelper = AriesAgentFunctions.shared
    var mediatorVerKey: String?
    var searchedConnections: [CloudAgentConnectionWalletModel]?
    weak var pageDelegate: OrganisationListDelegate?
    var searchKey: String? {
        didSet {
            updateSearchedItems()
        }
    }
    var connectionType: ConnectionType? = .All {
        didSet {
            updateSearchedItems()
        }
    }
    
    init(walletHandle: IndyHandle?, mediatorVerKey: String?) {
        self.walletHandle = walletHandle
        self.mediatorVerKey = mediatorVerKey ?? ""
    }
    
    func fetchOrgList(completion: @escaping (Bool) -> Void) {
        let walletHandler = self.walletHandle ?? IndyHandle()
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .getActiveConnections) {[weak self] (success, searchHandle, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandle,count: 100) {[weak self] (success, response, error) in
                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let resultModel = CloudAgentSearchConnectionModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? CloudAgentSearchConnectionModel
                if let records = resultModel?.records?.filter({ $0.value?.orgDetails?.name != "JWT"}) {
                    self?.connections = records
                    self?.updateSearchedItems()
                    completion(true)
                }else{
                    self?.connections = []
                    self?.searchedConnections = []
                    completion(false)
                }
            }
        }
    }
    
    func newConnectionConfigCloudAgent(label: String, theirVerKey: String,serviceEndPoint: String, routingKey: [String], imageURL: String,didCom:String,completion:@escaping(Bool)-> Void) {
        let walletHandler = self.walletHandle ?? IndyHandle()
        let connectionVC = ConnectionPopupViewController()
        connectionVC.showConnectionPopup(orgName: label, orgImageURL: imageURL, walletHandler: walletHandler, recipientKey: theirVerKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey, isFromDataExchange: false, didCom: didCom) { [weak self] (connModel,recipientKey,myVerKey, message)  in
            completion(true)
        }
    }
    
    func updateSearchedItems() {
        switch connectionType {
        case .All, .Organisations:
            self.searchedConnections = connections
        default:
            self.searchedConnections = []
            pageDelegate?.reloadData()
            return
        }
        if searchKey?.isEmpty ?? true {
            self.searchedConnections = connections
            pageDelegate?.reloadData()
            return
        }
        let filteredArray = self.connections?.filter({ (item) -> Bool in
            return (item.value?.theirLabel?.localizedUppercase.contains(searchKey?.localizedUppercase ?? "")) ?? false
        })
        self.searchedConnections = filteredArray
        pageDelegate?.reloadData()
        return
    }
    
    deinit {
        print("Org obj removed from memory")
    }
}
