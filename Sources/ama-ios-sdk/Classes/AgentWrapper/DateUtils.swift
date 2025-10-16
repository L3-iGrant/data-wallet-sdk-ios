//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 20/08/25.
//

import Foundation

class DateUtils {
    
    static let shared = DateUtils()
    
    func parseDate(from dateString: String?, formats: [String]) -> Date? {
        guard let dateString = dateString else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
    
}
