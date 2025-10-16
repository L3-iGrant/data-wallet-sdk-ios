//
//  Image.Extension.swift
//  dataWallet
//
//  Created by sreelekh N on 01/11/21.
//

import UIKit
import Photos
import ImageIO
import Kingfisher

extension UIImage {
    class func getImage(_ name: String, _ ifNotAvailable: String = "bellIcon") -> UIImage {
        if let customImage = UIImage(named: name) {
            return customImage
        } else if let systemImage = UIImage(systemName: name) {
            return systemImage
        }else if let sdK_image = UIImage.init(named: name, in: Constants.bundle, with: nil) {
            return sdK_image
        }else if let notSystem = UIImage(systemName: ifNotAvailable) {
            return notSystem
        } else if let notDevice = UIImage(named: ifNotAvailable) {
            return notDevice
        }
        return UIImage(named: "bellIcon") ?? UIImage()
    }
}

private var xoAssociationKey: UInt8 = 0

extension UIImageView {
    func loadFromUrl(_ url: String, placeHolder: String = "photo", shouldResize: Bool = true, completion: @escaping((UIImage?) -> Void) = { _ in}) {
        if url.isNotEmpty {
            if !shouldResize {
                self.kf.indicatorType = .activity
                self.kf.setImage(
                    with: url.toUrl,
                    placeholder: placeHolder.getImage(),
                    options: [
                        .loadDiskFileSynchronously
                    ], completionHandler: { [weak self] result in
                        switch result {
                        case .success(let data):
                            completion(placeHolder.getImage())
                        case .failure:
                            let image = self?.resizedImageWith(image: placeHolder.getImage(), targetSize: self?.bounds.size ?? CGSize.zero , placeholder:  placeHolder.getImage())
                            self?.image = image
                            completion(image)
                        }
                    })
            } else {
                let processor = DownsamplingImageProcessor(size: self.bounds.size)
                self.kf.indicatorType = .activity
                self.kf.setImage(
                    with: url.toUrl,
                    placeholder: placeHolder.getImage(),
                    options: [
                        .processor(processor),
                        .scaleFactor(UIScreen.main.scale),
                        .transition(.fade(0.4)),
                        .cacheOriginalImage,
                        .loadDiskFileSynchronously
                    ], completionHandler: { [weak self] result in
                        switch result {
                        case .success(let data):
                            completion(placeHolder.getImage())
                        case .failure:
                            let image = self?.resizedImageWith(image: placeHolder.getImage(), targetSize: self?.bounds.size ?? CGSize.zero, placeholder:  placeHolder.getImage())
                            self?.image = image
                            completion(image)
                        }
                    })
            }
        } else {
            //let image = self.resizedImageWith(image: placeHolder.getImage(), targetSize: self.bounds.size , placeholder: placeHolder.getImage())
            self.image = placeHolder.getImage()
            completion(placeHolder.getImage())
        }
    }
    
    func resizedImageWith(image: UIImage, targetSize: CGSize, placeholder: UIImage) -> UIImage {
        let imageSize = image.size
        let newWidth  = targetSize.width  / image.size.width
        let newHeight = targetSize.height / image.size.height
        var newSize: CGSize
        if (newWidth > newHeight) {
            newSize = CGSize(width: imageSize.width * newHeight, height: imageSize.height * newHeight)
        } else {
            newSize = CGSize(width: imageSize.width * newWidth,  height: imageSize.height * newWidth)
        }
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? placeholder
    }
    
    func stopDownload() {
        self.kf.cancelDownloadTask()
    }
}

extension UIButton {
    func loadFromUrl(_ url:String, placeHolder:String = "bellIcon") {
        if !url.isEmpty {
            let processor = DownsamplingImageProcessor(size: self.bounds.size)
            let modifier = AnyImageModifier { return $0.withRenderingMode(.alwaysOriginal) }
            self.kf.setImage(with: url.toUrl, for: .normal, placeholder: placeHolder.getImage(), options: [
                
                .imageModifier(modifier),
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.4)),
                .cacheOriginalImage,
                .loadDiskFileSynchronously,
                
            ], progressBlock: nil, completionHandler: { [weak self] result in
                switch result {
                case .success:
                    break
                case .failure:
                    let resizedImage = self?.resizedImageWith(image: placeHolder.getImage(), targetSize: self?.bounds.size ?? CGSize.zero, placeholder:  placeHolder.getImage())
                    self?.setImage(resizedImage?.withRenderingMode(.alwaysOriginal), for: .normal)
                }
            })
        } else {
            let resizedImage = self.resizedImageWith(image: placeHolder.getImage(), targetSize: self.bounds.size , placeholder:  placeHolder.getImage())
            self.setImage(resizedImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
    }
    
    func resizedImageWith(image: UIImage, targetSize: CGSize, placeholder:UIImage) -> UIImage {
        let imageSize = image.size
        let newWidth  = targetSize.width  / image.size.width
        let newHeight = targetSize.height / image.size.height
        var newSize: CGSize
        if (newWidth > newHeight) {
            newSize = CGSize(width: imageSize.width * newHeight, height: imageSize.height * newHeight)
        } else {
            newSize = CGSize(width: imageSize.width * newWidth,  height: imageSize.height * newWidth)
        }
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? placeholder
    }
}

extension UIImage {
    
    var getWidth: Int {
        get {
            let width = self.size.width
            return Int(width)
        }
    }
    
    var getHeight: Int {
        get {
            let height = self.size.height
            return Int(height)
        }
    }
}
