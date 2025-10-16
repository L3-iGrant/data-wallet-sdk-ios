//
//  ThirdPartyGroupViewModel.swift
//  dataWallet
//
//  Created by sreelekh N on 16/09/22.
//

import Foundation
protocol ThirdPartyGroupViewModelBind: ThirdPartyGroupViewController {
    func updateForsearch()
}

public struct ThirdPartyPreferenceModel {
    var name: String?
    var purpose: String?
    var id: String?
    var toggleStatus: Bool
    var dataAgreement: DataAgreementContext?
    var value: [ThirdPartyDus]?
}

final class ThirdPartyGroupViewModel {
    
    var searchKey = "" {
        didSet {
            self.updateSearchedItems()
        }
    }
    var filterIndex = 0 {
        didSet {
            self.updateSearchedItems(filterAction: true)
        }
    }
    var connectionModel: CloudAgentConnectionWalletModel?
    var sectors = ["All Sectors"]
    var responseData: [ThirdPartyPreferenceModel] = []
    var responseMainCarrier: [ThirdPartyPreferenceModel] = []
    weak var bind: ThirdPartyGroupViewModelBind?
    
    init(connectionModel: CloudAgentConnectionWalletModel) {
        self.connectionModel = connectionModel
        Task {
            UIApplicationUtils.showLoader()
            guard let data = await ThirdPartyDataSharing.shared.fetchPreferencesUsingOrgID(orgID: connectionModel.value?.orgDetails?.orgId ?? "") else { return }
            responseData = data
            responseMainCarrier = responseData
            let sectorsData = fetchSectorsFromPreference(from: responseMainCarrier)
            sectors.append(contentsOf: sectorsData)
            self.updateContent()
        }
        
    }
    
    func fetchSectorsFromPreference(from responseModel: [ThirdPartyPreferenceModel]) -> [String] {
        var sectors: [String] = []
        for item in responseModel {
            if let thirdPartyDus = item.value {
                for thirdParty in thirdPartyDus {
                    if let sector = thirdParty.sector {
                        if !(sectors.contains(sector)) {
                            sectors.append(sector)
                        }
                    }
                }
            }
        }
        return sectors
    }
    
    private func updateSearchedItems(filterAction: Bool = false) {
        let prefVals = self.responseMainCarrier.map { $0.value ?? [ThirdPartyDus]() }.reduce([ThirdPartyDus](), +)
        print(prefVals.count)
        let filteredArray = prefVals.filter({ (item) -> Bool in
            return ((item.controllerDetails?.organisationName?.lowercased() ?? "").contains(searchKey.lowercased()))
        })
        if searchKey == "" && filterAction {
            self.makeFilteredDataSorted(data: prefVals)
        } else if searchKey == "" {
            self.makeFilteredDataSorted(data: prefVals)
        } else {
            self.makeFilteredDataSorted(data: filteredArray)
        }
        return
    }
    
    private func makeFilteredDataSorted(data: [ThirdPartyDus]?) {
        guard var data = data?.group(by: { $0.sector }) else { return }
        self.responseData.removeAll()
        let filterValue = sectors[filterIndex]
        for (i, values) in data.enumerated() {
            let innerModel = values.value
            data[values.key] = innerModel
            if innerModel.isNotEmpty {
                var oldModel = self.responseMainCarrier.first { e in
                    e.id == innerModel[i].daInstanceID
                }
                oldModel?.value = innerModel
                let model = oldModel ?? ThirdPartyPreferenceModel(name: values.key, toggleStatus: false, value: innerModel)
                if filterIndex == 0 {
                    self.responseData.append(model)
                } else if values.key == filterValue {
                    self.responseData.append(model)
                }
            }
        }
        self.updateContent()
    }
    
    private func updateContent() {
        let sorted = self.responseData.sorted(by: { $0.name ?? "" < $1.name ?? "" })
        self.responseData = sorted
        self.bind?.updateForsearch()
    }
    
    func updateToggle(path: IndexPath) {
        Task{
            guard let connModel = self.connectionModel,let item = self.responseData[path.section].value?[path.row] else {return}
            let now = item.ddaInstancePermissionState
            let update = await ThirdPartySharingProtocols.updatePreferences(connectionModel: connModel, ddaInstanceId: item.ddaInstanceID ?? "", daInstanceId: item.daInstanceID ?? "", state: (now == .allow) ? PermissionState.disallow.rawValue : PermissionState.allow.rawValue)
            DispatchQueue.main.async {
                guard var item = self.responseData[path.section].value?[path.row] else {return}
                item.ddaInstancePermissionState = now == .allow ? .disallow : .allow
                self.responseData[path.section].value?[path.row] = item
                let updatedData = self.responseData[path.section]
                if let main = self.responseMainCarrier.firstIndex(where: { $0.id == updatedData.id }) {
                    self.responseMainCarrier[main].value = updatedData.value
                }
                if !update {
                    item.ddaInstancePermissionState = (item.ddaInstancePermissionState == .allow) ? .disallow : .allow
                }
                self.bind?.updateForsearch()
            }
        }
    }
    
    @objc func updateToggle(section: Int){
        Task{
            guard let connModel = self.connectionModel else {return}
            let item = self.responseData[section]
            let update = await ThirdPartySharingProtocols.updateAgreementLevel(connectionModel: connModel, instanceId: item.id ?? "", state: item.toggleStatus ? PermissionState.disallow.rawValue : PermissionState.allow.rawValue)
            DispatchQueue.main.async {
                var item = self.responseData[section]
                let now = item.toggleStatus
                item.toggleStatus = !now
                if let main = self.responseMainCarrier.firstIndex(where: { $0.id == item.id }) {
                    self.responseMainCarrier[main] = item
                }
                self.responseData[section] = item
                if !update {
                    let currentStatus = item.toggleStatus
                    item.toggleStatus = !currentStatus
                }
                self.bind?.updateForsearch()
            }
        }
    }
    
    //    private func setToggleStatus() {
    //        for (index, data) in self.responseData.enumerated() {
    //            if let filter = data.value?.map({ $0.ddaInstancePermissionState }) {
    //                print(filter)
    //                if filter.contains(.allow) {
    //                    self.responseData[index].toggleStatus = true
    //                }
    //            }
    //        }
    //    }
}
