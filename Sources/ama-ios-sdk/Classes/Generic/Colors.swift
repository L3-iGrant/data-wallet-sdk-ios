//
//  Colors.swift
//  dataWallet
//
//  Created by sreelekh N on 25/10/21.
//

import Foundation
import UIKit

enum AssetsColor: String {
    case walletBg
    case cardOddColor
}

extension UIColor {
    class func appColor(_ name: AssetsColor) -> UIColor? {
        return UIColor(named: name.rawValue,in: Constants.bundle, compatibleWith: nil)
    }
    
    //rgb(102, 102, 102)
    class func getColorFromRGBString(rgbString: String) -> UIColor? {
        let colorString = (rgbString.replacingOccurrences(of: "rgb(", with: "")).replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "")
        let colorArray = colorString.split(separator: ",").map { e in
            "\(e)".CGFloatValue()
        }
        if colorArray.isEmpty {
            return nil
        }
        guard let red = colorArray[0],
              let green = colorArray[1],
              let blue = colorArray[2]
        else {return nil}
        
        return UIColor.init(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: 1)
    }
}
