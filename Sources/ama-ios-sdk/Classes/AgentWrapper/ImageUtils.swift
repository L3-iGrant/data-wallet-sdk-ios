//
//  ImageUtils.swift
//  ama-ios-sdk
//
//  Created by iGrant on 02/08/25.
//

import Foundation
import UIKit
//import SVGKit

class ImageUtils {
    
    static let shared = ImageUtils()
    
    @MainActor func setRemoteImage(for imageView: UIImageView, imageUrl: String?, orgName: String?, bgColor: String? = nil, placeHolderImage: UIImage? = nil ) {
        if let imageUrl = imageUrl, !imageUrl.isEmpty {
//            if imageUrl.hasSuffix(".svg") {
//                if let svgURL = URL(string: imageUrl) {
//                    DispatchQueue.global().async {
//                        if let svgData = try? Data(contentsOf: svgURL) {
//                            let svgImage = SVGKImage(data: svgData)
//                            DispatchQueue.main.async {
//                                imageView.image = svgImage?.uiImage
//                            }
//                        } else {
//                            DispatchQueue.main.async {
//                                imageView.image = UIImage(named: "iGrant.io_DW_Logo")
//                            }
//                        }
//                    }
//                }
//            }else
            if imageUrl.hasPrefix("data:image") {
                if let base64String = (imageUrl.replacingOccurrences(of: " ", with: "+")).components(separatedBy: ",").last {
                    if let imageData = Data(base64Encoded: base64String) {
                        if let decodedImage = UIImage(data: imageData) {
                            imageView.image = decodedImage
                            if let bgColor = bgColor {
                                imageView.backgroundColor = UIColor(hex: bgColor)
                            }
                        } else {
                            print("Failed to decode Base64 image")
                            imageView.image = UIImage(named: "iGrant.io_DW_Logo")
                        }
                    }
                }
            } else if let imageData = Data(base64Encoded: imageUrl) {
                if let decodedImage = UIImage(data: imageData) {
                    imageView.image = decodedImage
                    if let bgColor = bgColor {
                        imageView.backgroundColor = UIColor(hex: bgColor)
                    }
                } else {
                    print("Failed to decode Base64 image")
                    imageView.image = UIImage(named: "iGrant.io_DW_Logo")
                }
            }
            else {
                UIApplicationUtils.shared.setRemoteImageOn(imageView, url: imageUrl, placeholderImage: placeHolderImage)
            }
        } else {
            guard let firstLetter = orgName?.first else { return }
            if let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100)) {
                imageView.image = profileImage
            } else {
                imageView.image = UIImage(named: "iGrant.io_DW_Logo")
            }
        }
    }
    
    func loadImage(from urlString: String, imageIcon: UIImageView, logoWidth: NSLayoutConstraint, logoHeight: NSLayoutConstraint) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                return
            }
            
            DispatchQueue.main.async {
                let logoImage = image.withRenderingMode(.alwaysOriginal)
                imageIcon.image = logoImage
                
                let estimateWidth: CGFloat = 150
                let estimateHeight: CGFloat = 40
                
                if logoImage.size.height > estimateHeight {
                    let ratio = estimateHeight / logoImage.size.height
                    logoWidth.constant = logoImage.size.width * ratio
                    logoHeight.constant = logoImage.size.height * ratio
                } else {
                    logoHeight.constant = logoImage.size.height
                    
                    if logoImage.size.width > estimateWidth {
                        let ratio = estimateWidth / logoImage.size.width
                        logoWidth.constant = logoImage.size.width * ratio
                        logoHeight.constant = logoImage.size.height * ratio
                    } else {
                        logoWidth.constant = logoImage.size.width
                    }
                }
            }
        }.resume()
    }
    
    func blurEffect(image: UIImage) -> UIImage {
        let currentFilter = CIFilter(name: "CIGaussianBlur")
        let beginImage = CIImage(image: image)
        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter!.setValue(10, forKey: kCIInputRadiusKey)

        let cropFilter = CIFilter(name: "CICrop")
        cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
        cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")

        var context = CIContext(options: nil)
        let output = cropFilter!.outputImage
        let cgimg = context.createCGImage(output!, from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        return processedImage
    }
    
}
