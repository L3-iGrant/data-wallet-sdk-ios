//
//  AppRatingPrompt.swift
//  dataWallet
//
//  Created by sreelekh N on 11/08/22.
//

import Foundation
import StoreKit
extension UIApplication {
    var foregroundActiveScene: UIWindowScene? {
        connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
    }
}

final class AppRatingPrompt {
    
    let runIncrementerSetting = "numberOfRuns"
    let minimumRunCount = 5
    
    func showAppReviewAlert() {
        guard let scene = UIApplication.shared.foregroundActiveScene else { return }
        let runs = getRunCounts()
        if (runs > minimumRunCount) {
            self.reset()
            if #available(iOS 14.0, *) {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
    
    private func reset() {
        let usD = UserDefaults()
        usD.setValuesForKeys([runIncrementerSetting: 0])
        usD.synchronize()
    }
    
    func incrementAppRuns() {
        let usD = UserDefaults()
        let runs = getRunCounts() + 1
        usD.setValuesForKeys([runIncrementerSetting: runs])
        usD.synchronize()
        
    }
    
    private func getRunCounts () -> Int {
        let usD = UserDefaults()
        let savedRuns = usD.value(forKey: runIncrementerSetting)
        var runs = 0
        if (savedRuns != nil) {
            runs = savedRuns as! Int
        }
        print("Run Counts are \(runs)")
        return runs
        
    }
}
