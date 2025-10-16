//
//  HapticManager.swift
//  Ramz
//
//  Created by sreelekh N on 13/12/21.
//

import UIKit
final class HapticManager {
    
    enum FeedbackType {
        case error
        case success
        case warning
        case light
        case medium
        case heavy
        case change
    }
    
    static func tapped(type: FeedbackType) {
        switch type {
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .change:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}
