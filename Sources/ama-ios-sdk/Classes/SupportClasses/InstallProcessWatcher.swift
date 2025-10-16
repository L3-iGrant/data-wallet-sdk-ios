//
//  InstallProcessWatcher.swift
//  dataWallet
//
//  Created by sreelekh N on 27/10/21.
//

import Foundation
struct InstallProcessWatcher {
    static func checkIfUpgrade() {
        if let currentVersion = Constants.bundle.object(forInfoDictionaryKey: UnknownAll.bundleVersion) as? String {
            let versionOfLastRun = UserDefaults.standard.versionOfLastRun
            if versionOfLastRun == nil {
                UserDefaults.standard.versionOfLastRun = currentVersion
            } else if versionOfLastRun != currentVersion {
                UserDefaults.standard.launchedBefore = true
                UserDefaults.standard.versionOfLastRun = currentVersion
            } else if versionOfLastRun == currentVersion {
                UserDefaults.standard.launchedBefore = true
            }
        }
    }
}
