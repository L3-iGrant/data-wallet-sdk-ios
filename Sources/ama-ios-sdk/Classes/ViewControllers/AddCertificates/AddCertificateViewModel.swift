//
//  AddCertificateViewModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 17/07/21.
//

import Foundation
import UIKit
import IndyCWrapper

protocol AddCertificateDelegate: AnyObject {
    func reloadData()
}

class AddCertificateViewModel {
    var notifications: [InboxModelRecord]?
    var searchedNotifications: [InboxModelRecord]?
    var searchedCardTypes: [AddCertificateItemModel]?
    let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
    var delegate: AddCertificateDelegate?
    var selectedCountriesArray: [Country] = []
    var cardTypes: [AddCertificateItemModel] = []
    
    var AllcardTypes: [AddCertificateItemModel] = [
        AddCertificateItemModel(title: "MyData Profile", subTitle: "International", mainImage:  "MyDataProfile".getImage(), subImage: nil , type: .My_data_profile, region: nil),
       AddCertificateItemModel(title: LocalizationSheet.generic.localize,
                                              subTitle: LocalizationSheet.connect_add.localize,
                                              mainImage: "qrcode.viewfinder".getImage(),
                                              subImage: nil,
                                              type: .other,
                                              region: nil),
        AddCertificateItemModel(title: "Aadhar", subTitle: "India", mainImage:   "Aadhaar_Logo.svg".getImage(), subImage:  "india-flag".getImage(), type: .Aadhar, region: [ "india"]),
        AddCertificateItemModel(title: "Passport of the European Union", subTitle: "European Economic Area", mainImage: "passportIcon".getImage(), subImage: "eu-flag".getImage(), type: .EU_Passport, region: ["europe"]),
        AddCertificateItemModel(title: "Singapore passport", subTitle: "Singapore", mainImage:  "passportIcon".getImage(), subImage: "singapore".getImage(), type: .EU_Passport, region: ["singapore"]),
        AddCertificateItemModel(title: "Digital Test Certificate", subTitle: "European Economic Area", mainImage:  "coronavirus".getImage(), subImage: "eu-flag".getImage() ,type: .euTestCertificate, region: ["europe"]),
       AddCertificateItemModel(title: "EBSI Certificates", subTitle: "European Union", mainImage:  "add-card".getImage(), subImage: "eu-flag".getImage() ,type: .EBSI_diploma, region: ["europe"]),

    ]
    
    
    func configForSelfAttestedCert(){
        cardTypes.removeAll()
        cardTypes = [
            AddCertificateItemModel(title: "Aadhar", subTitle: "India", mainImage:   "Aadhaar_Logo.svg".getImage(), subImage:  "india-flag".getImage(), type: .Aadhar, region: [ "india"]),
            AddCertificateItemModel(title: "Passport of the European Union", subTitle: "European Economic Area", mainImage:  "passportIcon".getImage(), subImage:  "eu-flag".getImage(), type: .EU_Passport, region: ["europe"]),
        ];
        self.searchedCardTypes = self.cardTypes
        delegate?.reloadData()
    }
    
    func configForAllCards(){
        cardTypes.removeAll()
        cardTypes = AllcardTypes
        self.searchedCardTypes = self.cardTypes
        delegate?.reloadData()
    }
    
    func fetchNotifications(completion: @escaping (Bool) -> Void) {
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, searchType:.getAllInboxOfferReceived) { [weak self](success, prsntnExchngSearchWallet, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: self?.walletHandler ?? IndyHandle(), searchWalletHandler: prsntnExchngSearchWallet, count: 100) {[weak self] (success, response, error) in
                let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: response)
                let searchInboxModel = SearchInboxModel.decode(withDictionary: recordResponse as NSDictionary? ?? NSDictionary()) as? SearchInboxModel
                if let records = searchInboxModel?.records {
                    self?.notifications = records
                    self?.searchedNotifications = self?.notifications
                    completion(true)
                }else{
                    self?.notifications = []
                    self?.searchedNotifications = self?.notifications
                    completion(false)
                }
            }
        }
    }
    
    func getSelectedCountries(){
        if let countriesString =  UserDefaults.standard.value(forKey: Constants.add_card_selected_countries) as? String, !countriesString.isEmpty{
            let countries = countriesString.split(separator: ",")
            let countriesModel = Countries.countries
            selectedCountriesArray.removeAll()
            for county in countries {
                if let selectedItem = countriesModel.first(where: { item in
                    (item.regionID ?? "") == county
                }){
                    selectedCountriesArray.append(selectedItem)
                }
            }
            var selectedCards: [AddCertificateItemModel] = []
            for item in countries {
                for card in cardTypes {
                    if ((card.region?.contains(String(item)) ?? false && !selectedCards.contains(card)) || (card.region == nil && !selectedCards.contains(card))){
                        selectedCards.append(card)
                        continue
                    }
                }
            }
            self.searchedCardTypes = selectedCards
        } else {
            self.searchedCardTypes = cardTypes
            selectedCountriesArray.removeAll()
        }
        delegate?.reloadData()
    }
    
    func updateSearchedItems(searchString: String){
        if searchString == "" {
            self.searchedNotifications = notifications
            self.searchedCardTypes = cardTypes
            delegate?.reloadData()
            return
        }
        let NotificationfilteredArray = self.notifications?.filter({ (item) -> Bool in
            let offer = item.value?.offerCredential
            let schemeSeperated = offer?.value?.schemaID?.split(separator: ":")
            let certName = "\(schemeSeperated?[2] ?? "")"
            return (certName.contains(searchString))
        })
        let CardsfilteredArray = self.cardTypes.filter({ (item) -> Bool in
            return (item.title?.contains(searchString)) ?? false || item.subTitle?.contains(searchString) ?? false
        })
        
        self.searchedNotifications = NotificationfilteredArray
        self.searchedCardTypes = CardsfilteredArray
        delegate?.reloadData()
        return
    }
}

struct AddCertificateItemModel: Hashable {
    var title: String?
    var subTitle: String?
    var mainImage: UIImage?
    var subImage: UIImage?
    var type: AddIDCardTypes?
    var region: [String]?
}

enum AddIDCardTypes: Int, CaseIterable {
    case Aadhar
    case EU_Passport
    case other
    case euTestCertificate
    case EBSI_diploma
    case EBSI_studentID
    case EBSI_verifiableID
    case My_data_profile
}
