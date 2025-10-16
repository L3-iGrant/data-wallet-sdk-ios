import Foundation
import SwiftUI

extension NSDictionary {

    /// Converts a NSDictionary to a Dedocable Optional
    ///
    /// - Parameters:
    ///     - docodable: Decodable.Type The type which this NSDictionaty should be decoded into
    /// - returns: Decodable?
    public func to(_ decodable: Decodable.Type ) -> Decodable? {
        return decodable.decode(withDictionary: self)
    }

}

extension Dictionary where Key == String , Value == Any {

    /// Converts a Dictionary<String,Any> to a Decodable Optional
    ///
    /// - Parameters:
    ///     - docodable: Decodable.Type The type which this NSDictionaty should be decoded into
    /// - returns: Decodable?
    public func to(_ decodable: Decodable.Type ) -> Decodable? {
        return decodable.decode(withHashableDictionary: self)
    }

}

extension Dictionary where Key == AnyHashable , Value == Any {

    /// Converts a Dictionary<AnyHashable,Any> to a Decodable Optional
    ///
    /// - Parameters:
    ///     - docodable: Decodable.Type The type which this NSDictionaty should be decoded into
    /// - returns: Decodable?
    public func fromAnyHashableTo(_ decodable: Decodable.Type ) -> Decodable? {
        return decodable.decode(withHashableDictionary: self)
    }

}


extension UIView {
    /**
     Rounds the given set of corners to the specified radius
     
     - parameter corners: Corners to round
     - parameter radius:  Radius to round to
     */
    func round(corners: UIRectCorner, radius: CGFloat) {
        _ = _round(corners: corners, radius: radius)
    }
    
    /**
     Rounds the given set of corners to the specified radius with a border
     
     - parameter corners:     Corners to round
     - parameter radius:      Radius to round to
     - parameter borderColor: The border color
     - parameter borderWidth: The border width
     */
    func round(corners: UIRectCorner, radius: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
        let mask = _round(corners: corners, radius: radius)
        addBorder(mask: mask, borderColor: borderColor, borderWidth: borderWidth)
    }
    
    /**
     Fully rounds an autolayout view (e.g. one with no known frame) with the given diameter and border
     
     - parameter diameter:    The view's diameter
     - parameter borderColor: The border color
     - parameter borderWidth: The border width
     */
    func fullyRound(diameter: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
        layer.masksToBounds = true
        layer.cornerRadius = diameter / 2
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor;
    }
    
}

private extension UIView {
    
    @discardableResult func _round(corners: UIRectCorner, radius: CGFloat) -> CAShapeLayer {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
        return mask
    }
    
    func addBorder(mask: CAShapeLayer, borderColor: UIColor, borderWidth: CGFloat) {
        let borderLayer = CAShapeLayer()
        borderLayer.name = "custom_border"
        borderLayer.path = mask.path
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.frame = bounds
        
        layer.addSublayer(borderLayer)
    }
    
}

extension UILabel {
    func calculateMaxLines(width: CGFloat?) -> Int {
        let maxSize = CGSize(width: (width ?? frame.size.width) - 10, height: CGFloat(Float.infinity)) //Added more padding to avoid mistakes
        let charSize = font.lineHeight
        let text = (self.text ?? "") as NSString
        let textSize = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font ?? Font.system(size: self.font.pointSize)], context: nil)
        let linesRoundedUp = Int(ceil(textSize.height/charSize))
        return linesRoundedUp
    }
    
    func addAasterisk(color: UIColor = UIColor.red) {
        let text = (self.text ?? "") + "*"
        let range = (text as NSString).range(of: "*")
        let attributedString = NSMutableAttributedString(string:text)
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color , range: range)
        self.attributedText = attributedString
    }
}

extension UIImage {
    
    convenience init(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: (image?.cgImage!)!)
    }
    
}

extension Int {
    func splitBytesBigEndian(size: Int) -> [UInt8] {
        var bytes:[UInt8] = []
        var shift: Int
        var step: Int
            shift = (size - 1) * 8
            step = -8
        for _ in 0...size {
            bytes.append(UInt8((self >> shift) & 0xff))
            shift += step
        }
        return bytes
    }
}

extension URL {
    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
