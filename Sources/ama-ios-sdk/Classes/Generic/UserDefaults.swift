//
//  UserDefaults.swift
//  dataWallet
//
//  Created by sreelekh N on 26/10/21.
//

import Foundation
extension UserDefaults {
    var launchedBefore: Bool? {
        get {
            return bool(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }

    var versionOfLastRun: String? {
        get {
            return string(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }
}

