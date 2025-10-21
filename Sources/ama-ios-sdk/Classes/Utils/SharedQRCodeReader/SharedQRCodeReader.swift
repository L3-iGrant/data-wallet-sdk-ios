//
//  SharedQRCodeReader.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 14/10/21.
//

import Foundation
import qr_code_scanner_ios
import Mantis
import UIKit

class SharedQRCodeReader {
    static let shared = SharedQRCodeReader()
    private init() {
        qrScanner.configure(delegate: self, input: .default)
    }
    let qrScanner = QRScannerView()
    
    fileprivate func processQRRawDataFromImage(_ orientationFixImage: UIImage) {
        let ciImage = CIImage(image: orientationFixImage)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        if let features = detector?.features(in: ciImage ?? CIImage()),!features.isEmpty {
            if let feature = features.first as? CIQRCodeFeature{
                if let binary = feature.symbolDescriptor?.errorCorrectedPayload{
                    let symbolVersion = feature.symbolDescriptor?.symbolVersion ?? 0
                    self.qrScanner.readQRCodeData(in: orientationFixImage,data: binary,symbolVersion: symbolVersion)
                }
            }
        } else {
            let config = Mantis.Config()
            let cropViewController = Mantis.cropViewController(image: orientationFixImage,
                                                               config: config)
            cropViewController.modalPresentationStyle = .fullScreen
            cropViewController.delegate = self
            let topVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController
            topVC?.present(cropViewController, animated: true)
            UIApplicationUtils.showErrorSnackbar(message: "Auto detect Failed. Please crop QRcode manually.".localizedForSDK())
        }
    }
    
    func getQRCodeDetails(imgData: Data){
        if let image = UIImage.init(data: imgData){
            let orientationFixImage = self.fixImageOrientation(image)
            if let QRString = self.qrScanner.getQRCodeDataFromImage(image: orientationFixImage){
                if QRString == "PK\u{03}\u{04}\n" {
                    processQRRawDataFromImage(orientationFixImage)
                }
                
            } else {
                processQRRawDataFromImage(orientationFixImage)
            }
        } else {
            UIApplicationUtils.showErrorSnackbar(message: "No QR Code detected from image".localizedForSDK())
        }
    }
    
    func getQRCodeDataFromPDF(data: Data){
        if let cgProvider = CGDataProvider.init(data: data as CFData) {
            
//            // Instantiate a `CGPDFDocument` from the PDF file's URL.
//            guard let document = CGPDFDocument(url as CFURL) else { return }
            guard let document = CGPDFDocument.init(cgProvider) else { return }
            // Get the first page of the PDF document. Note that page indices start from 1 instead of 0.
            guard let page = document.page(at: 1) else { return }

            // Fetch the page rect for the page we want to render.
            let pageRect = page.getBoxRect(.mediaBox)

            // Optionally, specify a cropping rect. Here, we don’t want to crop so we keep `cropRect` equal to `pageRect`.
            let cropRect = pageRect

            let renderer = UIGraphicsImageRenderer(size: cropRect.size)
            let img = renderer.image { ctx in
                // Set the background color.
                UIColor.white.set()
                ctx.fill(CGRect(x: 0, y: 0, width: cropRect.width, height: cropRect.height))

                // Translate the context so that we only draw the `cropRect`.
                ctx.cgContext.translateBy(x: -cropRect.origin.x, y: pageRect.size.height - cropRect.origin.y)

                // Flip the context vertically because the Core Graphics coordinate system starts from the bottom.
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

                // Draw the PDF page.
                ctx.cgContext.drawPDFPage(page)
            }
            DispatchQueue.main.async {
                if let imgData = img.pngData() {
                    self.getQRCodeDetails(imgData: imgData)
                } else {
                    UIApplicationUtils.showErrorSnackbar(message: "No QR Code detected from image".localizedForSDK())
                }
            }
        }
    }
    
    private func fixImageOrientation(_ image: UIImage)->UIImage {
        UIGraphicsBeginImageContext(image.size)
        image.draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }
}

extension SharedQRCodeReader: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        UIApplicationUtils.showErrorSnackbar(message: "No QR Code detected from image".localizedForSDK())
    }
    
    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess binary: [UInt8]) {
        debugPrint("binary -- \(binary)")
    }
    
    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        debugPrint("code -- \(code)")
    }
    
}

extension SharedQRCodeReader: CropViewControllerDelegate {
    func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Mantis.Transformation, cropInfo: Mantis.CropInfo) {
        
    }
    
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
        cropViewController.dismiss(animated: true)
    }
    
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {
        
    }
    
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {
        
    }
    
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation) {
        debugPrint(transformation);
        let ciImage = CIImage(image: cropped)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        if let features = detector?.features(in: ciImage ?? CIImage()),!features.isEmpty {
            if let feature = features.first as? CIQRCodeFeature{
                if let binary = feature.symbolDescriptor?.errorCorrectedPayload{
                    let symbolVersion = feature.symbolDescriptor?.symbolVersion ?? 0
                    self.qrScanner.readQRCodeData(in: cropped,data: binary,symbolVersion: symbolVersion)
                }
            }
        } else {
            UIApplicationUtils.showErrorSnackbar(message: "No QR Code detected from image".localizedForSDK())
        }
        cropViewController.dismiss(animated: true)
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        cropViewController.dismiss(animated: true)
    }
}
