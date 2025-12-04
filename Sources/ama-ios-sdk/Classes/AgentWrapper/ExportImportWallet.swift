//
//  ExportImportWallet.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 10/03/22.
//

import Foundation
import IndyCWrapper

enum ExportWalletType {
    case iCloud
    case dataPods
}

class ExportImportWallet: NSObject {
    static var shared = ExportImportWallet()
    private override init(){super.init()}
    
    func exportWallet(){
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        let fileManager = FileManager.default
        let documentsURL =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backUPPath = documentsURL.appendingPathComponent("Backup/\(AgentWrapper.shared.getCurrentDateTime(format: "dd-mm-yyyy,hhmmss"))")
        
        let export_config = [
            "path": backUPPath.path,
            "key": "datawallet",
        ]
        AgentWrapper.shared.exportWallet(withHandle: walletHandler, exportConfigJson: export_config.toString() ?? "") { error in
            if error?._code != 0 {
                debugPrint("failed")
            }else{
                debugPrint("success")
            }
        }
    }
    
    fileprivate func uploadFileToDataPods(path: String, fileData: Data, completion: @escaping((Bool) -> ())) {
        DataPodsUtils.shared.getAccessForUser(url: DataPodsUtils.shared.userProvidedURL) { accessToken, _  in
            DataPodsUtils.shared.createFolder { folderCreated in
                if folderCreated {
                    DataPodsUtils.shared.uploadFile(fileName: path, mimeType: ".db", fileData: fileData){ success in
                        UIApplicationUtils.hideLoader()
                        completion(success)
                    }
                }
            }
        }
    }
    
    func exportWallet(type: ExportWalletType, completion: @escaping((Bool) -> ())){
        UIApplicationUtils.showLoader(message: "Exporting...".localizedForSDK())
        
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        let fileManager = FileManager.default
        
        //Since indy cannot create file in iCloud documents, we need to save the path to temp doc first and move to iCloud
        let tempDocURL = FileManager.default.temporaryDirectory
        let tempBackUpFile = tempDocURL.appendingPathComponent("\(AgentWrapper.shared.getCurrentDateTime(format: "dd-MM-yyyy,HHmmss"))")
        
        let export_config = [
            "path": tempBackUpFile.path,
            "key": "datawallet",
        ]
        AgentWrapper.shared.exportWallet(withHandle: walletHandler, exportConfigJson: export_config.toString() ?? "") {[weak self] error in
            if error?._code != 0 {
                debugPrint("failed -- \(error?.localizedDescription)")
                completion(false)
            }else{
                debugPrint("success")
                DispatchQueue.main.async {
                    let path = "\(AgentWrapper.shared.getCurrentDateTime(format: "dd-MM-yyyy-hhmmss")).db"
                    
                    switch type {
                    case .iCloud:
                        if let ubiquityURL = Constants.iCloudBackupURL{
                            if !fileManager.fileExists(atPath: ubiquityURL.path) {
                                do {
                                    try fileManager.createDirectory(at: ubiquityURL, withIntermediateDirectories: true, attributes: nil)
                                } catch {
                                    print("Failed to create backup directory: \(error.localizedDescription)")
                                    UIApplicationUtils.hideLoader()
                                    return
                                }
                            }
                            let destinationURL = ubiquityURL.appendingPathComponent("\(path)")
                            do {
                                //                                try fileManager.copyItem(atPath: tempBackUpFile.path, toPath: destinationURL.path)
                                try FileManager.default.setUbiquitous(true, itemAt: tempBackUpFile, destinationURL: destinationURL)
                                debugPrint("copied to cloud")
                                UIApplicationUtils.showSuccessSnackbar(message: "backup_and_restore_backup_completed".localize)
                                UIApplicationUtils.hideLoader()
                                completion(true)
                            } catch {
                                completion(false)
                                print("Failed to create backup directory: \(error.localizedDescription)")
                                UIApplicationUtils.hideLoader()
                                return
                            }
                        } else {
                            completion(false)
                            UIApplicationUtils.hideLoader()
                            debugPrint("Error setting file as ubiquitous")
                        }
                    case.dataPods:
                            do {
                                let fileData = try Data(contentsOf: tempBackUpFile)
                                self?.uploadFileToDataPods(path: path, fileData: fileData,completion: completion)
                            } catch {
                                // Handle any errors that occur while reading the file
                                print("Error reading file: \(error)")
                                UIApplicationUtils.hideLoader()
                            }
                        }
                }
            }
        }
    }
    
    func exportWallet(path: String){
        
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        let fileManager = FileManager.default
        let documentsURL =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        //Since indy cannot create file in iCloud documents, we need to save the path to temp doc firat and move to iCloud
        let tempDocURL = FileManager.default.temporaryDirectory
        let tempBackUpFile = tempDocURL.appendingPathComponent("\(AgentWrapper.shared.getCurrentDateTime(format: "dd-MM-yyyy,hhmmss"))")
        
        
        let export_config = [
            "path": tempBackUpFile.path,
            "key": "datawallet",
        ]
        AgentWrapper.shared.exportWallet(withHandle: walletHandler, exportConfigJson: export_config.toString() ?? "") {[weak self] error in
            if error?._code != 0 {
                debugPrint("failed -- \(error?.localizedDescription)")
            }else{
                debugPrint("success")
                DispatchQueue.main.async {
                    
                    let url = URL.init(fileURLWithPath: path)
                    if url.startAccessingSecurityScopedResource(){
                        defer{
                            url.stopAccessingSecurityScopedResource()
                        }
                        do{
                            let path = "\(AgentWrapper.shared.getCurrentDateTime(format: "dd-MM-yyyy,hhmmss")).db"
                            let backUPPath = url.appendingPathComponent(path)
                            let copiedSuccess = try fileManager.copyItem(atPath: tempBackUpFile.path, toPath: backUPPath.path)
                            debugPrint("copied -- \(copiedSuccess)")
                            if let ubiquityURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("DataWallet"){
                                try fileManager.createDirectory(at: ubiquityURL, withIntermediateDirectories: true, attributes: nil)
                                let destinationURL = ubiquityURL.appendingPathComponent("\(path)")
                                try fileManager.setUbiquitous(true, itemAt: tempBackUpFile, destinationURL: destinationURL)
                            } else {
                                debugPrint("Error setting file as ubiquitous")
                            }
                        }catch{
                            debugPrint(error.localizedDescription)
                        }
                    }
                }
            }
        }
    }
    
    func importWallet(path: String, completion: @escaping((Bool) -> ())) {
        
        debugPrint("Show loader started")
        let url = getDownloadedFileFor(URL.init(fileURLWithPath: path))
        let tempDocURL = FileManager.default.temporaryDirectory
        let tempBackUpFile = tempDocURL.appendingPathComponent("\(AgentWrapper.shared.getCurrentDateTime(format: "dd-MM-yyyy,hhmmss"))")
        do {
            try FileManager.default.copyItem(at: url, to: tempBackUpFile)
            let auth = AuthIdModel()
            let config = auth.config
            let credentials = auth.cred
            let configJson = ["path": tempBackUpFile.path, "key": "datawallet"]
            AriesMobileAgent.shared.deleteWallet(completion: { success in
                if success ?? false {
                    DataPodsUtils.shared.clearData()
                    AgentWrapper.shared.importWallet(withConfig: config, credentials: credentials, importConfigJson: configJson.toString() ?? "") { error in
                        UIApplicationUtils.hideLoader()
                        defer{
                            url.stopAccessingSecurityScopedResource()
                        }
                        if error?._code != 0 {
                            debugPrint("failed")
                            completion(false)
                            return
                        }else{
                            debugPrint("success")
                            completion(true)
                        }
                    }
                }
            })
        }catch{
            UIApplicationUtils.hideLoader()
            debugPrint(error.localizedDescription)
            completion(false)
        }
    }
    
    func getDownloadedFileFor(_ fileURL: URL) -> URL {
        let fileManager = FileManager.default
        var lastPathComponent = fileURL.lastPathComponent
        if lastPathComponent.contains(".icloud") {
            // Delete the "." which is at the beginning of the file name
            do {
                try fileManager.startDownloadingUbiquitousItem(at: fileURL)
            } catch {
                print("Unexpected error: \(error).")
            }
            lastPathComponent.removeFirst()
            let folderPath = fileURL.deletingLastPathComponent().path
            let downloadedFilePath = folderPath + "/" + lastPathComponent.replacingOccurrences(of: ".icloud", with: "")
            var isDownloaded = false
            
            while !isDownloaded {
                if fileManager.fileExists(atPath: downloadedFilePath) {
                    isDownloaded = true
                }
            }
            return URL.init(fileURLWithPath: downloadedFilePath)
        } else {
            fileURL.startAccessingSecurityScopedResource()
            return fileURL
        }
    }
    
    func fileSize(forURL url: Any) -> Double {
        var fileURL: URL?
        var fileSize: Double = 0.0
        if (url is URL) || (url is String)
        {
            if (url is URL) {
                fileURL = url as? URL
            }
            else {
                fileURL = URL(fileURLWithPath: url as! String)
            }
            var fileSizeValue = 0.0
            try? fileSizeValue = (fileURL?.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).allValues.first?.value as! Double?)!
            if fileSizeValue > 0.0 {
                fileSize = (Double(fileSizeValue) / (1024 * 1024))
            }
        }
        return fileSize
    }
    
    func checkAutoBackup(){
        
    }
}
