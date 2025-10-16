//
//  VersionCheck.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 20/02/23.
//

import Foundation
import Alamofire
import UIKit

class VersionCheck {
    
    func isUpdateAvailable(callback: @escaping (Bool)->Void) {

        let bundleId = Constants.bundle.infoDictionary!["CFBundleIdentifier"] as! String
        AF.request("https://itunes.apple.com/lookup?bundleId=\(bundleId)").responseData { response in
            switch response.result {
            case .success(let value):
                if let json = try? JSONSerialization.jsonObject(with: value) as? NSDictionary, let results = json["results"] as? NSArray, let entry = results.firstObject as? NSDictionary, let versionStore = entry["version"] as? String, let versionLocal = Constants.bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
                    let arrayStore = versionStore.split(separator: ".").compactMap { Int($0) }
                    let arrayLocal = versionLocal.split(separator: ".").compactMap { Int($0) }
                    
                    if arrayLocal.count != arrayStore.count {
                        callback(true) // different versioning system
                        return
                    }
                    // check each segment of the version
                    if versionStore.compare(versionLocal, options: .numeric) == .orderedDescending {
                        //store version is newer
                            callback(true)
                            return
                    }
                }
                callback(false) // no new version or failed to fetch app store version
            case .failure(let error):
                print(error)
                callback(false)
            }
        }
    }
    
    func showAlert(){
        let alertMessage = "\nGet the latest version to enjoy new features, improvements, and bug fixes. To update, simply tap update and follow the prompts.\n\nThank you for using Data Wallet! "
        let alertController = UIAlertController(title: "Update Available", message: alertMessage, preferredStyle: .alert)

        let action = UIAlertAction(title: "Update", style: .default) { (action:UIAlertAction!) in
            if let url = URL(string: "https://itunes.apple.com/app/1546551969") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            alertController.dismiss(animated: true)
        }
        
        let cancel =  UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction!) in
            alertController.dismiss(animated: true)
        }
        

        alertController.addAction(action)
        alertController.addAction(cancel)

        // Present alert controller
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            rootVC.present(alertController, animated: true, completion: nil)
        } else {
            UIApplicationUtils.shared.getTopVC()?.present(alertController, animated: true, completion:nil)
        }
    }
}
