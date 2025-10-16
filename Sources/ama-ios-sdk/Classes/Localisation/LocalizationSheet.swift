//
//  LocalizationSheet.swift
//  dataWallet
//
//  Created by sreelekh N on 30/01/22.
//

import Foundation
struct LocalizationSheet {
    static let all = "connection_all"
    static let connection_organisations = "connection_organisations"
    static let connection_people = "connection_people"
    static let connection_devices = "connection_devices"
    static let search_connections = "search_connections"
    static let agree_add_data_to_wallet = "agree_add_data_to_wallet"
    static let generic = "generic_card"
    static let connect_add = "connect_and_add"
    static let ticket_no = "ticket_no"
    static let registration = "registration"
    static let ticket = "parking_ticket"
}

extension String {
    var localize: String {
        return self.localizedForSDK()
    }
}
