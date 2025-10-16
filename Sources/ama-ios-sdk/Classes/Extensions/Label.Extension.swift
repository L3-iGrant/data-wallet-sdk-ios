//
//  Label.Extension.swift
//  dataWallet
//
//  Created by sreelekh N on 27/12/21.
//

import Foundation
import UIKit

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(boundingBox.width)
    }
}

extension UILabel {

    func addBlurrEffect() {
        // Avoid adding multiple blur views
        if let existing = subviews.first(where: { $0 is TSBlurEffectView }) as? TSBlurEffectView {
            existing.intensity = 0.7
            return
        }

        let blurEffectView = TSBlurEffectView()
        blurEffectView.intensity = 0.7
        blurEffectView.backgroundColor = .clear
       
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false

        // Insert below the text
        insertSubview(blurEffectView, at: 0)

        NSLayoutConstraint.activate([
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func removeBlurEffect() {
        subviews
            .filter { $0 is TSBlurEffectView }
            .forEach { $0.removeFromSuperview() }
    }
}

class TSBlurEffectView: UIVisualEffectView {

    private var animator: UIViewPropertyAnimator?
    var intensity: CGFloat = 1.0 {
        didSet {
            applyBlur()
        }
    }

    override init(effect: UIVisualEffect? = nil) {
        super.init(effect: effect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        applyBlur()
    }

    private func applyBlur() {
        animator?.stopAnimation(true)
        effect = nil

        let blurEffect = UIBlurEffect(style: .regular)
        animator = UIViewPropertyAnimator(duration: 1, curve: .linear) { [weak self] in
            self?.effect = blurEffect
        }

        let clamped = min(max(intensity / 10, 0.01), 1.0)
        animator?.fractionComplete = clamped
    }

    deinit {
        animator?.stopAnimation(true)
    }
    
}

extension Array {
    func at(_ index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
