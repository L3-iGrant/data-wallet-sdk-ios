//
//  SettingsPageViewModel.swift
//  dataWallet
//
//  Created by sreelekh N on 06/09/22.
//

import Foundation
struct SettingsSections {
    let title: String
    var content: [SettingsRow]
    
}

struct SettingsRow {
    let label: String
    var renderFor: SettingsRenderFor
}

final class SettingsPageViewModel {
    
    var content = [SettingsSections(title: "LANGUAGE",
                                    content: [SettingsRow(label: "",
                                                          renderFor: .arrow)]),
                   SettingsSections(title: "LEDGER NETWORK",
                                    content: [SettingsRow(label: "",
                                                          renderFor: .arrow)]),
                   SettingsSections(title: "", content: [SettingsRow(label: "Security",
                                                                     renderFor: .toggle),
                                                         SettingsRow(label: "Backup and Storage",
                                                                     renderFor: .arrow),
                                                         SettingsRow(label: "My Shared Data",
                                                                     renderFor: .arrow),
                                                         SettingsRow(label: "Regions",
                                                                     renderFor: .arrow)]),
                   SettingsSections(title: "", content: [SettingsRow(label: "tell_friend",
                                                                     renderFor: .arrow),
                                                         SettingsRow(label: "rate_app",
                                                                     renderFor: .arrow),
                                                         SettingsRow(label: "about_key",
                                                                     renderFor: .arrow)])
    ]
    var selectedCountriesArray: [Country] = []
    
}
