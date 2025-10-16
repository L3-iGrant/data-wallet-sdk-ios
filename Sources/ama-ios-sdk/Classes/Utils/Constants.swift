//
//  Constants.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 06/01/21.
//

import Foundation

struct Constants {
    
    static let bundleModule = Bundle.module
    //Notifications
    public static let didRecieveCertOffer = Notification.Name(rawValue: "io.igrant.received.certOffer")
    public static let didReceiveDataExchangeRequest = Notification.Name(rawValue: "io.igrant.received.dataExchangeRequest")
    public static let reloadWallet = Notification.Name(rawValue: "io.igrant.wallet.reload")
    public static let reloadOrgList = Notification.Name(rawValue: "io.igrant.OrganisationList.reload")
    public static let handleSharedQR = Notification.Name(rawValue: "io.igrant.handleSharedQR")
    //Strings
    public static let userDefault_ledger = "Ledger"
    public static let userDefault_language = "Language"
    public static let ledger_igrant_old_sandbox = "iGrant.io Sandbox Old"
    public static let ledger_igrant_sandbox = "iGrant.io Sandbox"
    public static let ledger_sovrin_builder = "Sovrin Builder"
    public static let ledger_sovrin_live = "Sovrin Live"
    public static let ledger_sovrin_sandbox = "Sovrin Sandbox"
    public static let bundle = UIApplicationUtils.shared.getResourcesBundle() ?? Bundle(for: UIApplicationUtils.self)

    public static let ledger_default_path = bundle.path(forResource: "igrant_sandbox_genesis", ofType: "txn") ?? ""
    //UserDefault
    public static let add_card_selected_countries = "selected_countries"

    public static let exchangeDataQuickActionNotify = "exchangeDataQuickActionNotify"
    
    public static let sharedExtensionImageData = "shared_image"
    public static let sharedExtensionPKPassData = "shared_pkpass"
    public static let sharedExtensionPDF = "shared_pdf"
    public static let padding: CGFloat = 20

    //BackupFileURL
    public static let iCloudBackupURL = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.io.iGrant.DataWallet")?.appendingPathComponent("DataWallet").appendingPathComponent("Backup")
    
    //Auto backup
    static var autoBackupEnabled: Bool {
        get{
            return UserDefaults.standard.value(forKey: "AutoBackup") as? Bool ?? true
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "AutoBackup")
        }
    }
    
    //backup type
    static var selectedBackupType: Int {
        get{
            return UserDefaults.standard.value(forKey: "BackupType") as? Int ?? 0
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "BackupType")
        }
    }
    
    static var autoBackupDate: Date {
        get{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let dateString = UserDefaults.standard.value(forKey: "AutoBackupDate") as? String,let date = dateFormatter.date(from: dateString) {
                return date
            } else {
                return Date()
            }
        }
        set{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = dateFormatter.string(from: newValue)
            UserDefaults.standard.set(dateString, forKey: "AutoBackupDate")
        }
    }
    
    static var needBackup: Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let dateString = UserDefaults.standard.value(forKey: "AutoBackupDate") as? String,let date = dateFormatter.date(from: dateString) {
            let date1 = date
            let date2 = Date()
            let calendar = Calendar.current

            // Compare if the two dates are exactly one month apart
            if let difference = calendar.dateComponents([.month], from: date1, to: date2).month, difference >= 1 {
                return true
            } else {
                return false
            }
        }else {
            return false
        }
    }
}
