//
//  Constants.swift
//  dataWallet
//
//  Created by sreelekh N on 28/10/21.
//

import Foundation
import UIKit

struct AppData {
    static let keyWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first
}

struct SBInstance {
    //SDK changes
    static let sbMain = UIStoryboard(name:"ama-ios-sdk", bundle: Bundle.module)

}

struct UnknownAll {
    static let nibMap = "identifierToNibNameMap"
    static let bundleVersion = "CFBundleShortVersionString"
}
