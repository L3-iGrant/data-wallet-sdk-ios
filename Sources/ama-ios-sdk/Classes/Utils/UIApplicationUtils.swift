//
//  UIApplicationUtils.swift
//  Indy_Demo
//
//  Created by Mohamed Rebin on 20/10/20.
//

import Foundation
import UIKit
import SwiftMessages
import Kingfisher
import SVProgressHUD
//import DynamicBlurView
import Reachability

class UIApplicationUtils {
    
    static let shared = UIApplicationUtils()
    let ledgerConfigToast = SwiftMessages()
    private init(){}
    
    func getTopVC() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
            // topController should now be your topmost view controller
        }
        return nil
    }
    
    func getPostString(params: [String:Any]) -> String {
        var data = [String]()
        for(key, value) in params {
            data.append(key + "=\(value)")
        }
        return data.map { String($0) }.joined(separator: "&")
    }
    
    func convertStringToDictionaryAny(text: String) -> [String:Any]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }
    
    func getResourcesBundle() -> Bundle? {
//        return nil
        
        //SDK
                let bundle = Bundle(for: UIApplicationUtils.self)
                guard let resourcesBundleUrl = bundle.resourceURL?.appendingPathComponent("ama-ios-sdk.bundle") else {
                    return nil
                }
                return Bundle.module
    }
    
    func getJsonString(for Dict: [String: Any?]) -> String {
        let jsonData = try? JSONSerialization.data(withJSONObject: Dict, options: [])
        let valueString = String(data: jsonData!, encoding: .utf8) ?? ""
        return valueString
    }
    
    func convertToDictionary(text: String) -> [String: Any?]? {
        return convertStringToDictionary(text: text)
    }
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
                return json
            } catch {
                debugPrint("Something went wrong \(error.localizedDescription)")
            }
        }
        return nil
    }
    
    func processUnpaackedMessage(unpackedData: Data) -> Data?{
        if var messageModel = try? JSONSerialization.jsonObject(with: unpackedData, options: []) as? [String : Any] {
            let messageString = messageModel["message"] as? String
            var msgDict = UIApplicationUtils.shared.convertToDictionary(text: messageString ?? "")
            let items = msgDict?["Items"] as? [[String: Any]] ?? []
            var modifiedItems: [[String: Any]] = []
            for var item in items {
                if let strValue = item["Data"] as? String, let value = UIApplicationUtils.shared.convertStringToDictionary(text: strValue) {
                    item["Data"] = value
                    modifiedItems.append(item)
                }
            }
            msgDict?["Items"] = modifiedItems
            messageModel["message"] = msgDict?.toString()
            return messageModel.toString()?.utf8Encoded
        }
        return nil
    }
    
    func calcAge(birthday: String) -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd"
        let birthdayDate = dateFormater.date(from: birthday)
        let calendar: NSCalendar! = NSCalendar(calendarIdentifier: .gregorian)
        let now = Date()
        let calcAge = calendar.components(.year, from: birthdayDate!, to: now, options: [])
        let age = calcAge.year
        return age != nil ? "\(age!)" : "NA"
    }
    func convertImageToBase64String (img: UIImage) -> String {
        return img.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
    }
    
    func convertBase64StringToImage (imageBase64String:String) -> UIImage? {
        let imageData = Data.init(base64Encoded: imageBase64String, options: .init(rawValue: 0))
        let image = UIImage(data: imageData!)
        return image
    }
    
    func decodeDict(dict: [String: Any?], boolKeys:[String]? = []) -> [String: Any] {
        var dictionary = [String: Any]()
        
        for key in dict.keys {
            if (boolKeys ?? []).contains(key){
                if let boolValue = (dict[key] as? NSNumber) as? Bool {
                    dictionary[key] = boolValue
                }
            }else if let intValue = dict[key] as? Int {
                dictionary[key] = intValue
            } else if let stringValue = dict[key] as? String {
                if let isDict = UIApplicationUtils.shared.convertToDictionary(text: stringValue){
                    dictionary[key] = decodeDict(dict: isDict,boolKeys: boolKeys)
                }else{
                    dictionary[key] = stringValue
                }
            } else if let doubleValue = dict[key] as? Double {
                dictionary[key] = doubleValue
            } else if let nestedDictionary = dict[key] as? [String:Any] {
                dictionary[key] = decodeDict(dict: nestedDictionary,boolKeys: boolKeys)
            }else if let nestedArray = dict[key] as? [Any] {
                dictionary[key] = decodeArray(array: nestedArray,boolKeys: boolKeys)
            } else {
                dictionary[key] = dict[key] as Any?
            }
        }
        return dictionary
    }
    
    func decodeArray(array: [Any],boolKeys:[String]? = []) -> [Any] {
        var tempArray = [Any]()
        
        for key in array {
            //            if let value = key as? Bool {
            //                tempArray.append(value)
            //            } else
            if let intValue = key as? Int {
                tempArray.append(intValue)
            } else if let stringValue = key as? String {
                if let isDict = UIApplicationUtils.shared.convertToDictionary(text: stringValue){
                    tempArray.append(decodeDict(dict: isDict,boolKeys:boolKeys))
                }else{
                    tempArray.append(stringValue)
                }
            } else if let doubleValue = key as? Double {
                tempArray.append(doubleValue)
            } else if let nestedDictionary = key as? [String:Any] {
                tempArray.append(decodeDict(dict: nestedDictionary,boolKeys:boolKeys))
            } else if let nestedArray = key as? [Any] {
                tempArray.append(decodeArray(array: nestedArray,boolKeys: boolKeys))
            } else {
            }
        }
        return tempArray
    }
    
    @MainActor func setRemoteImageOn(_ imageView:UIImageView, url:String?, forceDownload: Bool = false,showPlaceholder: Bool = true,placeholderImage: UIImage? = nil ){
        let placeholder = placeholderImage ?? UIImage(named: "placeholder", in: self.getResourcesBundle(), compatibleWith: nil)
        if let imageUrl = url, let URL = URL(string: imageUrl ) {
            var options: KingfisherOptionsInfo = []
            options.append(KingfisherOptionsInfoItem.transition(.fade(1)))
            if forceDownload {
                options.append(KingfisherOptionsInfoItem.forceRefresh)
            }
            imageView.kf.setImage(with: URL,
                                  placeholder: showPlaceholder ? placeholder : nil,
                                  options: options)
        } else {
            imageView.image = showPlaceholder ? placeholder : nil
        }
    }
    
    func profileImageCreatorWithAlphabet(withAlphabet alphabet: Character, size: CGSize, backgroundColor: UIColor = .lightGray, textColor: UIColor = .white, font: UIFont = UIFont.systemFont(ofSize: 50)) -> UIImage? {
        // Create a graphics context
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        // Fill background color
        backgroundColor.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // Draw the alphabet character
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let textSize = String(alphabet).size(withAttributes: attributes)
        let textRect = CGRect(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        String(alphabet).draw(in: textRect, withAttributes: attributes)
        
        // Get the image from the context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        return image
    }
    
    internal static func showErrorSnackbar(withTitle: String? = "", message: String,navViewController: UIViewController? = nil) {
        DispatchQueue.main.async {
            let error = MessageView.viewFromNib(layout: .messageView)
            error.configureTheme(.error)
            error.configureContent(title: withTitle!, body: message)
            error.button?.isHidden = true
            error.configureDropShadow()
            //        SwiftMessages.sharedInstance.defaultConfig.dimMode = .none
            //        SwiftMessages.sharedInstance.defaultConfig.duration = .seconds(seconds: 3)
            
            SwiftMessages.show(view: error)
        }
    }
    
    internal static func showSuccessSnackbar(withTitle: String? = "", message: String,navToNotifScreen: Bool = false) {
        DispatchQueue.main.async {
            if EBSIWallet.shared.viewMode == .BottomSheet {
                let navigationController = UIApplicationUtils.shared.getTopVC()
                let success = MessageView.viewFromNib(layout: .messageView)
                success.configureTheme(.success)
                success.backgroundColor = #colorLiteral(red: 0.2666666667, green: 0.5803921569, blue: 0.2666666667, alpha: 1)
                success.configureContent(title: withTitle!, body: message)
                success.configureDropShadow()
                success.button?.isHidden = true
                if navToNotifScreen {
                    success.tapHandler = { _ in
                        if (!navToNotifScreen){
                            return
                        }
                        SwiftMessages.hide()
                        DispatchQueue.main.async {
                            if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:Bundle.module).instantiateViewController( withIdentifier: "NotificationListViewController") as? NotificationListViewController {
                                navigationController?.dismiss(animated: true)
                            }
                        }
                    }
                }
                SwiftMessages.show(view: success)

            } else {
                let navigationController = UIApplicationUtils.shared.getTopVC() as? UINavigationController
                let success = MessageView.viewFromNib(layout: .messageView)
                success.configureTheme(.success)
                success.backgroundColor = #colorLiteral(red: 0.2666666667, green: 0.5803921569, blue: 0.2666666667, alpha: 1)
                success.configureContent(title: withTitle!, body: message)
                success.configureDropShadow()
                success.button?.isHidden = true
                if navToNotifScreen {
                    success.tapHandler = { _ in
                        if (!navToNotifScreen){
                            return
                        }
                        SwiftMessages.hide()
                        DispatchQueue.main.async {
                            if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:Bundle.module).instantiateViewController( withIdentifier: "NotificationListViewController") as? NotificationListViewController {
                                navigationController?.pushViewController(controller, animated: true)
                            }
                        }
                    }
                }
                SwiftMessages.show(view: success)

            }
        }
    }
    
    internal static func showLoader(){
        DispatchQueue.main.async {
            SVProgressHUD.show()
        }
    }
    
    internal static func showLoader(message: String){
        DispatchQueue.main.async {
            SVProgressHUD.show(withStatus: message)
        }
    }
    
    func showLedgerConfigToast(){
        DispatchQueue.main.async {
            let view = MessageView.viewFromNib(layout: .statusLine)
            view.backgroundColor = .gray
            var config = SwiftMessages.Config()
            config.presentationStyle = .bottom
            config.presentationContext = .window(windowLevel: .statusBar)
            config.prefersStatusBarHidden = false
            config.duration = .forever
            //            config.dimMode = .gray(interactive: true)
            config.interactiveHide = false
            config.preferredStatusBarStyle = .darkContent
            //        config.eventListeners.append() { event in
            //            if case .didHide = event { print("yep") }
            //        }
            view.bodyLabel?.textColor = .white
            view.bodyLabel?.text = "Configuring pool...".localizedForSDK()
            view.bodyLabel?.font = UIFont.systemFont(ofSize: 15)
            self.ledgerConfigToast.show(config: config, view: view)
        }
    }
    
    func hideLedgerConfigToast(){
        DispatchQueue.main.async {
            self.ledgerConfigToast.hide()
        }
    }
    
    internal static func hideLoader(){
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension Int {
    var nonNegative: Int {
        clamped(to: 0...Int.max)
    }
}
extension Collection {
    var tailLength: Int {
        (count - 1).nonNegative
    }
    
    var head: SubSequence { prefix(1) }
    var tail: SubSequence { suffix(tailLength) }
}

extension String {
    
    var uppercaseFirst: String {
        head.localizedUppercase + tail
    }
    
    var words: [String] {
        components(separatedBy: " ")
    }
    
    var uppercaseFirstWords: String {
        words
            .map(\.uppercaseFirst)
            .joined(separator: " ")
    }
    
    func decodeBase64() -> String? {
        do {
            var st = self
                .replacingOccurrences(of: "_", with: "/")
                .replacingOccurrences(of: "-", with: "+")
            let remainder = self.count % 4
            if remainder > 0 {
                st = self.padding(toLength: self.count + 4 - remainder,
                                  withPad: "=",
                                  startingAt: 0)
            }
            let data = try Base64.decode(st)
            return String.init(decoding: data, as: UTF8.self)
        }catch{
            debugPrint(error)
            return nil
        }
    }
    
    func decodeBase64_first8bitRemoved() -> String? {
        do {
            var st = self
                .replacingOccurrences(of: "_", with: "/")
                .replacingOccurrences(of: "-", with: "+")
            let remainder = self.count % 4
            if remainder > 0 {
                st = self.padding(toLength: self.count + 4 - remainder,
                                  withPad: "=",
                                  startingAt: 0)
            }
            var data = try Base64.decode(st)
            data.removeFirst(8)
            return String.init(decoding: data, as: UTF8.self)
        }catch{
            debugPrint(error)
            return nil
        }
    }
    
    func encodeBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
    
    //    Here is a string extension for Swift 5 that you can convert a string to UnsafePointer<UInt8> and UnsafeMutablePointer<Int8>
    
    func toUnsafePointer() -> UnsafePointer<UInt8>? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        let stream = OutputStream(toBuffer: buffer, capacity: data.count)
        stream.open()
        let value = data.withUnsafeBytes {
            $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
        }
        guard let val = value else {
            return nil
        }
        stream.write(val, maxLength: data.count)
        stream.close()
        
        return UnsafePointer<UInt8>(buffer)
    }
    
    func toUnsafeMutablePointer() -> UnsafeMutablePointer<Int8>? {
        return strdup(self)
    }
    
}

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)).flatMap { $0 as? [String: Any] }
    }
}


extension NSMutableAttributedString {
    var fontSize:CGFloat { return 14 }
    var boldFont:UIFont { return  UIFont.boldSystemFont(ofSize: fontSize) }
    var normalFont:UIFont { return UIFont.systemFont(ofSize: fontSize)}
    
    func bold(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font : boldFont
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    
    func normal(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font : normalFont,
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    /* Other styling methods */
    func orangeHighlight(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font :  normalFont,
            .foregroundColor : UIColor.white,
            .backgroundColor : UIColor.orange
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    
    func blackHighlight(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font :  normalFont,
            .foregroundColor : UIColor.white,
            .backgroundColor : UIColor.black
            
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    
    func error(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font :  normalFont,
            .foregroundColor : UIColor.red,
            .backgroundColor : UIColor.white
            
        ]
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    
    func underlined(_ value:String) -> NSMutableAttributedString {
        
        let attributes:[NSAttributedString.Key : Any] = [
            .font :  normalFont,
            .underlineStyle : NSUnderlineStyle.single.rawValue
            
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
}

extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}

extension UIColor {
    class func AriesDefaultThemeColor() -> UIColor {
        return UIColor(red: 0, green: 0.2, blue: 0.55, alpha:1)
    }
}

extension UITableView {
    
    func setEmptyMessage(_ message: String) {
        let height = self.frame.height/2 - 50
        let iconHeight: CGFloat = 40.0
        let view = UIView.init(frame: CGRect.init(x: 20, y: 0, width: self.frame.width - 40, height: self.frame.height))
        let messageLabel = UILabel.init(frame: CGRect.init(x: 20, y: height + iconHeight + 5, width: self.frame.width - 40, height: 60))
        messageLabel.text = message
        messageLabel.textColor = .darkGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 15)
        
        let noDataIcon = UIImageView.init(frame: CGRect.init(x: 0, y: height, width:  self.frame.width, height: iconHeight))
        noDataIcon.image = UIImage.init(named: "ic_block", in: UIApplicationUtils.shared.getResourcesBundle(), compatibleWith: nil)
        noDataIcon.contentMode = .scaleAspectFit
        view.addSubview(noDataIcon)
        view.addSubview(messageLabel)
        self.backgroundView = view
    }
    
    func restore() {
        self.backgroundView = nil
    }
}

extension UICollectionView {
    
    func setEmptyMessage(_ message: String) {
        let height = self.frame.height/2 - 50
        let iconHeight: CGFloat = 40.0
        let view = UIView.init(frame: CGRect.init(x: 20, y: 0, width: self.frame.width - 40, height: self.frame.height))
        let messageLabel = UILabel.init(frame: CGRect.init(x: 20, y: height + iconHeight + 5, width: self.frame.width - 40, height: 60))
        messageLabel.text = message
        messageLabel.textColor = .darkGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 15)
        
        let noDataIcon = UIImageView.init(frame: CGRect.init(x: 0, y: height, width:  self.frame.width, height: iconHeight))
        noDataIcon.image = UIImage.init(named: "ic_block", in: UIApplicationUtils.shared.getResourcesBundle(), compatibleWith: nil)
        noDataIcon.contentMode = .scaleAspectFit
        
        view.addSubview(noDataIcon)
        view.addSubview(messageLabel)
        self.backgroundView = view
    }
    
    func restore() {
        self.backgroundView = nil
    }
}

extension UIView {
    func setShadowWithColor(color: UIColor?, opacity: Float?, offset: CGSize?, radius: CGFloat?, viewCornerRadius: CGFloat?) {
        //layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: viewCornerRadius ?? 0.0).CGPath
        layer.shadowColor = color?.cgColor ?? UIColor.black.cgColor
        layer.shadowOpacity = opacity ?? 1.0
        layer.shadowOffset = offset ?? CGSize.zero
        layer.shadowRadius = radius ?? 0
        layer.cornerRadius = viewCornerRadius ?? 0
    }
    
    func addBlur() {
        //        let blurEffect = UIBlurEffect(style: .light)
        //        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        //        blurredEffectView.frame = self.bounds
        //        self.addSubview(blurredEffectView)
        //        let blurView = DynamicBlurView(frame: bounds)
        //        blurView.blurRadius = 10
        //        blurView.blendColor = .white.withAlphaComponent(0.7)
        //        blurView.backgroundColor = .clear
        //        addSubview(blurView)
    }
    
    func removeBlur() {
        subviews.forEach { subview in
            if subview.tag == 123454321 {
                subview.removeFromSuperview()
            }
        }
    }
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

extension UIColor {
    func inverse () -> UIColor {
        var r:CGFloat = 0.0; var g:CGFloat = 0.0; var b:CGFloat = 0.0; var a:CGFloat = 0.0;
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return UIColor(red: 1.0-r, green: 1.0 - g, blue: 1.0 - b, alpha: a)
        }
        return .black // Return a default colour
    }
}

extension UISearchBar {
    
    private func getViewElement<T>(type: T.Type) -> T? {
        
        let svs = subviews.flatMap { $0.subviews }
        guard let element = (svs.filter { $0 is T }).first as? T else { return nil }
        return element
    }
    
    func setTextFieldColor(color: UIColor) {
        self.searchTextField.backgroundColor = color
    }
    
    func removeBg() {
        if let view = self.subviews.first?.subviews.last?.subviews.first?.subviews.first?.subviews.first {
            view.isHidden = true
        }
    }
}

extension Date {
    
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    var epochTime: String {
        return "\(Int(Date().timeIntervalSince1970))"
    }
    
    var unixTimestamp: Int64 {
        return Int64(self.timeIntervalSince1970 * 1_000)
    }
    
    var epochTimeISO8601: String {
        let unixTime = self.unixTimestamp
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        let iso8601DateFormatter = ISO8601DateFormatter()
        iso8601DateFormatter.formatOptions = [.withInternetDateTime]
        let string = iso8601DateFormatter.string(from: date)
        return string
    }
}

extension URL {
    
    func appending(_ queryItem: String, value: String?) -> URL {
        
        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }
        
        // Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
        
        // Create query item
        let queryItem = URLQueryItem(name: queryItem, value: value)
        
        // Append the new query item in the existing query items array
        queryItems.append(queryItem)
        
        // Append updated query items array in the url component object
        urlComponents.queryItems = queryItems
        
        // Returns the url from new url components
        return urlComponents.url!
    }
}

extension String {
    func decodeJWT(jwtToken jwt: String) throws -> [String: Any] {
        func base64Decode(_ base64: String) throws -> Data? {
            let base64 = base64
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let padded = base64.padding(toLength: ((base64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            guard let decoded = Data(base64Encoded: padded) else {
                debugPrint("DecodeErrors.badToken")
                return nil
            }
            return decoded
        }

        func decodeJWTPart(_ value: String) throws -> [String: Any] {
            guard let bodyData = try base64Decode(value) else { return [:]}
            let json = try JSONSerialization.jsonObject(with: bodyData, options: [])
            guard let payload = json as? [String: Any] else {
                debugPrint("DecodeErrors.other")
                return [:]
            }
            return payload
        }

        let segments = jwt.components(separatedBy: ".")
        return try decodeJWTPart(segments[1])
    }
}

extension Encodable {
    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if let jsonData = try? encoder.encode(self) {
            return String(data: jsonData, encoding: .utf8)
        }
        
        return nil
    }
}

