//
//  BlurredTextTableViewCell.swift
//  dataWallet
//
//  Created by Mumthasir mohammed on 05/07/23.
//

import UIKit

class BlurredTextTableViewCell: UITableViewCell {

    @IBOutlet var lblTitle: UILabel!
    @IBOutlet weak var viewBlurredLabel: UIView!
    @IBOutlet weak var lblBlurred: BlurredLabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var didValueLabel: BlurredLabel!
    @IBOutlet weak var mainStackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        didValueLabel.isBlurring = true
        didValueLabel.isUserInteractionEnabled = true
        didValueLabel.becomeFirstResponder()
        viewBlurredLabel.isUserInteractionEnabled = true
        lblTitle.text = "DID"
        viewBlurredLabel.isHidden = true
      
      addGesture()
    }
    
    private func addGesture() {
        isUserInteractionEnabled = true
        addGestureRecognizer(
            UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleLongPressed(_:))
            )
        )
    }
    
    @objc func handleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let gestureView = gesture.view else {
            return
        }
        let menuController = UIMenuController.shared
        
        guard !menuController.isMenuVisible, gestureView.canBecomeFirstResponder else {
            return
        }
        
        gestureView.becomeFirstResponder()
        menuController.menuItems = [
            UIMenuItem(
                title: "general_copy".localizedForSDK(),
                action: #selector(handleCopyAction(_:))
            ),UIMenuItem(
                title: "general_share".localizedForSDK(),
                action: #selector(handleShareAction(_:))
            )
        ]
        menuController.showMenu(from: self, rect: bounds)
    }
    
    func configureData(didText: String) {
        didValueLabel.text = didText
        setupStackView()
    }
    
    func setupStackView() {
        let maxWidth = contentView.frame.width - 40
        let blurredLabelSize = didValueLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        if blurredLabelSize.width > maxWidth - lblTitle.intrinsicContentSize.width - 8 {
            mainStackView.axis = .vertical
        } else {
            mainStackView.axis = .horizontal
        }
    }
    
    override var canBecomeFirstResponder: Bool {
           return true
    }
    
    @objc internal func handleShareAction(_ controller: UIMenuController) {
        let items = [self.didValueLabel.text]
        let ac = UIActivityViewController(activityItems: items as [Any], applicationActivities: nil)
        self.window?.rootViewController?.present(ac, animated: true, completion: nil)
    }
    
    @objc internal func handleCopyAction(_ controller: UIMenuController) {
        UIPasteboard.general.string = self.didValueLabel.text
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    override func prepareForReuse() {
        self.alpha = 1
        self.contentView.isUserInteractionEnabled = true
    }
}
