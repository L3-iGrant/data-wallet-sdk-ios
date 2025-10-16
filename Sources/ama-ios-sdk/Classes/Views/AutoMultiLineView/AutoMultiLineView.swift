//
//  AutoMultiLineView.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 30/09/21.
//

import UIKit

@IBDesignable
class AutoMultiLineView: UIView, NibLoadable {
    var contentView: UIView?
    
    @IBOutlet weak var baseStackView: UIStackView!
    @IBOutlet weak  var valueLabel: BlurredLabel!
    @IBOutlet weak  var nameLabel: UILabel!
    @IBOutlet weak var seperatorView: UILabel!
    
    var initialWidth : CGFloat?
    var valueTextAlignment: NSTextAlignment?
    var bgColor: UIColor?
    var labelColor: UIColor? {
        didSet{
            self.backgroundColor = labelColor?.withAlphaComponent(0.1)
            self.valueLabel.textColor = labelColor
            self.nameLabel.textColor = labelColor
            self.seperatorView.backgroundColor = labelColor?.withAlphaComponent(0.6)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    var name: String?{
        didSet{
            nameLabel.text = name
        }
    }
    var value: String?{
        didSet{
            valueLabel.text = value
            if initialWidth == nil {
                initialWidth = self.frame.width/2
            }
            if valueLabel.calculateMaxLines(width: initialWidth) > 1 {
                baseStackView.axis = .vertical
                baseStackView.alignment = .fill
                baseStackView.distribution = .fill
                baseStackView.spacing = 10
                valueLabel.textAlignment = valueTextAlignment ?? .right
            } else {
                baseStackView.axis = .horizontal
                baseStackView.alignment = .leading
                baseStackView.distribution = .fillProportionally
                baseStackView.spacing = 10
                valueLabel.textAlignment = valueTextAlignment ?? .right
            }
        }
    }
    
    var attributedValue: NSAttributedString?{
        didSet{
            valueLabel.attributedText = attributedValue
            if initialWidth == nil {
                initialWidth = self.frame.width/2
            }
            if valueLabel.calculateMaxLines(width: initialWidth) > 1 {
                baseStackView.axis = .vertical
                baseStackView.alignment = .fill
                baseStackView.distribution = .fill
                baseStackView.spacing = 10
                valueLabel.textAlignment = .right
            } else {
                baseStackView.axis = .horizontal
                baseStackView.alignment = .leading
                baseStackView.distribution = .fillProportionally
                baseStackView.spacing = 10
                valueLabel.textAlignment = .right
            }
        }
    }
    
    func setBlur(value: Bool){
        valueLabel.isBlurring = value
    }
    
    func sharedInit() {
        self.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.showMenu))
        gesture.numberOfTapsRequired = 2
        gesture.delegate = self
        self.addGestureRecognizer(gesture)
    }
    
    @objc func showMenu(_ recognizer: UITapGestureRecognizer) {
        self.becomeFirstResponder()
        
        let menu = UIMenuController.shared
        
        let locationOfTouchInLabel = recognizer.location(in: self)
        
        if !menu.isMenuVisible {
            var rect = bounds
            rect.origin = locationOfTouchInLabel
            rect.size = CGSize(width: 1, height: 1)
            
            menu.showMenu(from: self, rect: rect)
        }
    }
    
    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general
        
        board.string = valueLabel.text
        
        let menu = UIMenuController.shared
        
        menu.setMenuVisible(false, animated: true)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
}

public protocol NibLoadable {
    static var nibName: String { get }
}

public extension NibLoadable where Self: UIView {
    
    static var nibName: String {
        return String(describing: Self.self) // defaults to the name of the class implementing this protocol.
    }
    
    static var nib: UINib {
        let bundle = Bundle(for: Self.self)
        return UINib(nibName: Self.nibName, bundle: Constants.bundle)
    }
    
    func setupFromNib() {
        guard let view = Self.nib.instantiate(withOwner: self, options: nil).first as? UIView else { fatalError("Error loading \(self) from nib") }
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        view.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        view.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        view.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
}

extension AutoMultiLineView: UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: valueLabel)
        debugPrint(point)
        debugPrint(valueLabel.bounds.contains(point))
        return valueLabel.bounds.contains(point)
        //        if touch.view == valueLabel {
        //            return false
        //         }
        //         return true
    }
}
