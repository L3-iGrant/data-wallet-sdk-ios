//
//  AadharQRUtils.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 15/10/21.
//

import Foundation
import UIKit

class AadharQRUtils{
    static let shared = AadharQRUtils()
    private let SEPARATOR_BYTE = 255
    private var VTC_INDEX = 15
    private var imageStartIndex: Int = 0
    private var imageEndIndex: Int = 0
    private var decodedData: [String] = []
    private var emailMobilePresent = 0
    private init() { }
    
    func populateAadharQRDetails(code: String) {
        let xmlStr = code
        let parser = ParseXMLData(xml: xmlStr)
        let jsonStr = parser.parseXML()
        let jsonData = Data(jsonStr.utf8)
        let data = code.data(using: String.Encoding.ascii)
        let QRCodeImage = generateQRFrom(data: data ?? Data())
        if let aadharScannedModel = try? JSONDecoder().decode(AadharScannedModel.self, from: jsonData), let aadharModel = aadharScannedModel.printLetterBarcodeData {
            
            let qr = UIApplicationUtils.shared.convertImageToBase64String(img: QRCodeImage ?? UIImage())
            let model = AadharStateViewModel(model: AadharModel.init(model: aadharModel, qrCode: qr, userImageBase64: ""))
            let vc = CertificateViewController(pageType: .aadhar(isScan: true))
            vc.viewModel.aadhar = model
            DispatchQueue.main.async {
                if let topVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                    topVC.popViewController(animated: false)
                    topVC.pushViewController(vc, animated: true)
                }
            }
        } else {
            do {
                let byteScanData = decimalStringToUInt8Array(code.replacingOccurrences(of: "\n", with: ""))
                let decompScanData = try Data.init(bytes: byteScanData, count: byteScanData.count).gunzipped()
                let decompByteScanData = [UInt8](decompScanData);
                let parts: [[UInt8]]? = separateData(source: decompByteScanData)
                if (parts?.count == 0) {
                    UIApplicationUtils.showErrorSnackbar(message: "Invalid QR code")
                    return
                }
                
                // 5. decode extracted data to string
                let aadharModel = decodeData(encodedData: parts ?? [])
                
                // 7. Email and Mobile number
                decodeMobileEmail(decompressedData: decompByteScanData)
                
                // 8. Extract Image
                let image = decodeImage(decompressedData: decompByteScanData)
                
                if(aadharModel.printLetterBarcodeData != nil) {
                    
                    if let model = aadharModel.printLetterBarcodeData {
                        let qr = UIApplicationUtils.shared.convertImageToBase64String(img: QRCodeImage ?? UIImage())
                        let model = AadharStateViewModel(model: AadharModel.init(model: model, qrCode: qr, userImageBase64: UIApplicationUtils.shared.convertImageToBase64String(img: image )))
                        let vc = CertificateViewController(pageType: .aadhar(isScan: true))
                        vc.viewModel.aadhar = model
                        DispatchQueue.main.async {
                            if let topVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                                topVC.popViewController(animated: false)
                                topVC.pushViewController(vc, animated: true)
                            }
                        }
                    }
                    
                    return
                }
                // use your compressed data
            } catch {
                debugPrint(error.localizedDescription)
                UIApplicationUtils.showErrorSnackbar(message: "Invalid QR code")
                if let topVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                    topVC.popViewController(animated: false)
                }
            }
        }
    }
    
    func generateQRFrom(data: Data) -> UIImage? {
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil}
        // Input the data
        qrFilter.setValue(data, forKey: "inputMessage")
        // Get the output image
        guard let qrImage = qrFilter.outputImage else { return nil}
        // Scale the image
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQrImage = qrImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledQrImage, from: scaledQrImage.extent) else { return nil }
        let processedImage = UIImage(cgImage: cgImage)
        return processedImage
    }
    
    private func separateData(source: [UInt8]?) -> [[UInt8]] {
        var separatedParts: [[UInt8]] = []
        var begin = 0
        if (source != nil){
            for i in source?.indices ?? [].indices {
                if ((source?[i] ?? 0) == SEPARATOR_BYTE) {
                    // skip if first or last byte is separator
                    if (i != 0 && i != (source?.count ?? 0) - 1) {
                        var temp = Array(source?[begin...i] ?? [])
                        temp.removeAll { e in
                            e == SEPARATOR_BYTE
                        }
                        separatedParts.append(temp)// Arrays.copyOfRange(source, begin, i))
                    }
                    begin = i + 1
                    // check if we have got all the parts of text data
                    if (separatedParts.count == VTC_INDEX + 1) {
                        // this is required to extract image data
                        imageStartIndex = begin
                        break
                    }
                }
            }
        }
        return separatedParts
    }
    
    private func decodeImage(decompressedData: [UInt8]?) -> UIImage {
        // image start and end indexes are calculated in functions : separateData and decodeMobileEmail
        let imageBytes = Array((decompressedData ?? [])[imageStartIndex...(imageEndIndex + 1)])
        // (decompressedData, imageStartIndex, imageEndIndex + 1)
        return UIImage(data: Data.init(bytes: imageBytes, count: imageBytes.count)) ?? UIImage()
    }
    
    private func decodeData(encodedData: [[UInt8]]?) -> AadharScannedModel {
        //        var i = encodedData?.makeIterator()
        //        while (i?.next() != nil) {
        //            decodedData.append(String(data: Data.init(bytes: i?.next() ?? [], count: i?.next()?.count ?? 0), encoding: .windowsCP1250) ?? "")
        //        }
        decodedData.removeAll()
        for item in encodedData ?? [] {
            decodedData.append(String(data: Data.init(bytes: item, count: item.count) , encoding: .windowsCP1250) ?? "")
        }
        
        // set the value of email/mobile present flag
        emailMobilePresent = Int(decodedData.first ?? "0") ?? 0
        
        let aadhaarCard = AadharScannedModel(printLetterBarcodeData: PrintLetterBarcodeData.init(
            pc: decodedData[10],
            name: decodedData[2],
            dist: decodedData[6],
            subdist: decodedData[14],
            state:decodedData[12],
            po: decodedData[11],
            gender: decodedData[4],
            house: decodedData[8],
            co: decodedData[5],
            yob: decodedData[3],
            lm: decodedData[7],
            uid: "",
            vtc: decodedData[15],
            location: decodedData[9]))
        
        // populate decoded data
        //           aadhaarCard!!.name = decodedData?.get(2)
        //           aadhaarCard!!.dob = decodedData?.get(3)
        //           aadhaarCard!!.gender = decodedData?.get(4)
        //           aadhaarCard!!.co = decodedData?.get(5)
        //           aadhaarCard!!.dist = decodedData?.get(6)
        //           aadhaarCard!!.lm = (decodedData?.get(7))
        //           aadhaarCard!!.house = (decodedData?.get(8))
        //           aadhaarCard!!.loc = (decodedData?.get(9))
        //           aadhaarCard!!.pincode = (decodedData?.get(10))
        //           aadhaarCard!!.po = (decodedData?.get(11))
        //           aadhaarCard!!.state = (decodedData?.get(12))
        //                                                                   aadhaarCard!!.street = (decodedData?.get(13))
        //           aadhaarCard!!.subdist = (decodedData?.get(14))
        //           aadhaarCard!!.vtc = (decodedData?.get(15))
        return aadhaarCard
    }
    
    func decimalStringToUInt8Array(_ decimalString: String) -> [UInt8] {
        
        // Convert input string into array of Int digits
        let digits = Array(decimalString).compactMap { Int(String($0)) }
        
        // Nothing to process? Return an empty array.
        guard digits.count > 0 else { return [] }
        
        let numdigits = digits.count
        
        // Array to hold the result, in reverse order
        var bytes = [UInt8]()
        
        // Convert array of digits into array of Int values each
        // representing 6 digits of the original number.  Six digits
        // was chosen to work on 32-bit and 64-bit systems.
        // Compute length of first number.  It will be less than 6 if
        // there isn't a multiple of 6 digits in the number.
        var ints = Array(repeating: 0, count: (numdigits + 5)/6)
        var rem = numdigits % 6
        if rem == 0 {
            rem = 6
        }
        var index = 0
        var accum = 0
        for digit in digits {
            accum = accum * 10 + digit
            rem -= 1
            if rem == 0 {
                rem = 6
                ints[index] = accum
                index += 1
                accum = 0
            }
        }
        
        // Repeatedly divide value by 256, accumulating the remainders.
        // Repeat until original number is zero
        while ints.count > 0 {
            var carry = 0
            for (index, value) in ints.enumerated() {
                var total = carry * 1000000 + value
                carry = total % 256
                total /= 256
                ints[index] = total
            }
            
            bytes.append(UInt8(truncatingIfNeeded: carry))
            
            // Remove leading Ints that have become zero.
            while ints.count > 0 && ints[0] == 0 {
                ints.remove(at: 0)
            }
        }
        
        // Reverse the array and return it
        return bytes.reversed()
    }
    
    private func decodeMobileEmail(decompressedData: [UInt8]?) {
        if (decompressedData != nil) {
            switch (emailMobilePresent) {
            case 3:
                // both email mobile present
                // set image end index, it will be used to extract image data
                imageEndIndex = (decompressedData?.count ?? 0) - 1 - 256 - 32 - 32
            case 2:
                // only mobile
                // set image end index, it will be used to extract image data
                imageEndIndex = (decompressedData?.count ?? 0) - 1 - 256 - 32
            case 1:
                // only email
                // set image end index, it will be used to extract image data
                imageEndIndex = (decompressedData?.count ?? 0) - 1 - 256 - 32
            default:
                // no mobile or email
                // set image end index, it will be used to extract image data
                imageEndIndex = (decompressedData?.count ?? 0) - 1 - 256
            }
        }
    }
}
