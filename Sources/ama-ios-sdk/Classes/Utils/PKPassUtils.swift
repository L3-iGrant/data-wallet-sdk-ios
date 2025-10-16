//
//  PKPassUtils.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 24/11/21.
//

import Foundation
import UIKit

class PKPassUtils {
    static let shared = PKPassUtils()
    private var completionHandler : (([String: Any]?,Data?) -> ())?

    func getDictionaryFromPKPassData(data:Data, completion: @escaping (([String: Any]?,Data?) -> ())) {
        self.completionHandler = completion
        zip(data: data)
    }

    func zip(data: Data) {
        var archiveURL = URL(fileURLWithPath: NSTemporaryDirectory())
        archiveURL.appendPathComponent("archievedFile")
        archiveURL.appendPathExtension("zip")
        debugPrint(archiveURL.absoluteString)
        do {
            try data.write(to: archiveURL)
            debugPrint("ADDED")
            extract(fileName: "archievedFile.zip")
        } catch {
            debugPrint(error)
        }
    }

    func extract(fileName : String){
        let fileManager = FileManager()
        let file = fileName
        // let currentWorkingPath = fileManager.currentDirectoryPath
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = dir.appendingPathComponent(file)
        let unzippedFileURL = dir.appendingPathComponent("unzippedFile")
        debugPrint("zip url -- \(fileURL)")
        debugPrint("unzip url -- \(unzippedFileURL)")
        do {
            //                 try fileManager.createDirectory(at: fileURL, withIntermediateDirectories: true, attributes: nil)
            if fileManager.fileExists(atPath: unzippedFileURL.path){
                try fileManager.removeItem(atPath: unzippedFileURL.path)
            }
            try fileManager.unzipItem(at: fileURL, to: unzippedFileURL)
            read(fileName: "pass.json")
            debugPrint("EXTRACTED")
        } catch {
            debugPrint("Extraction of ZIP archive failed with error:\(error)")
        }
    }

    func read(fileName : String){
        let file = fileName //this is the file. we will write to and read from it
        var dir = URL(fileURLWithPath: NSTemporaryDirectory())
        dir = dir.appendingPathComponent("unzippedFile")
        let fileURL = dir.appendingPathComponent(file)
        //reading
        do {
            let text2 = try String(contentsOf: fileURL, encoding: .utf8)
            debugPrint(text2)
            if let data = try? Data(contentsOf: fileURL) {
                let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                debugPrint(dict)
                let imageFileURL = dir.appendingPathComponent("logo@2x.png")
                let imageData = try? Data(contentsOf: imageFileURL)
                //icon@2x
                completionHandler?(dict,imageData)
//                completionHandler?(nil,covidIndiaCertificateModel,self.QRCodeImage)
            }
        }
        catch {
            debugPrint("Text reading error -- \(error.localizedDescription)")
        }
    }

    func getImageofTransit(transit: TransitType?) -> UIImage{
        switch transit ?? .PKTransitTypeAir {
            case .PKTransitTypeAir:
            return "airplane_icon".getImage()
            case .PKTransitTypeTrain:
                return "train".getImage()
        }
    }

    func getImageofTransitForWalletList(transit: TransitType?) -> UIImage{
        switch transit ?? .PKTransitTypeAir {
            case .PKTransitTypeAir:
               return "airplane_icon".getImage()
            case .PKTransitTypeTrain:
                return "train".getImage()
        }
    }
}
