//
//  DataAgreementTableViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 21/09/21.
//

import UIKit

class DataAgreementTableViewCell: UITableViewCell {

    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var valueView: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var autoMultiLineView: AutoMultiLineView!
    
    var bgColor: UIColor?{
        didSet {
            self.autoMultiLineView.bgColor = bgColor
        }
    }
    var labelColor: UIColor? {
        didSet {
            self.autoMultiLineView.labelColor = labelColor
            self.backgroundColor = .clear
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.autoMultiLineView.sharedInit()
    }
    
    func borderConfigForTop() {
        clearBorder()
        nameView.clipsToBounds = true
        nameView.layer.cornerRadius = 10
        valueView.clipsToBounds = true
        valueView.layer.cornerRadius = 10
        nameView.layer.maskedCorners = [.layerMinXMinYCorner]
        valueView.layer.maskedCorners = [.layerMaxXMinYCorner]
        nameView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).cgColor
        nameView.layer.borderWidth = 1
        valueView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).cgColor
        valueView.layer.borderWidth = 1
    }
    
    func borderConfigForBottom(){
        clearBorder()
        nameView.clipsToBounds = true
        nameView.layer.cornerRadius = 10
        valueView.clipsToBounds = true
        valueView.layer.cornerRadius = 10
        nameView.layer.maskedCorners = [.layerMinXMaxYCorner]
        valueView.layer.maskedCorners = [.layerMaxXMaxYCorner]
        nameView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).cgColor
        nameView.layer.borderWidth = 1
        valueView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).cgColor
        valueView.layer.borderWidth = 1
    }
    
    func borderConfigForMiddle(){
        clearBorder()
        nameView.addBorders(edges: [.right,.left,.bottom], color:  #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), thickness: 1)
        valueView.addBorders(edges: [.right,.bottom], color:  #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), thickness: 1)
    }

    func clearBorder() {
        self.layer.mask = nil
        nameView.layer.maskedCorners = []
        valueView.layer.maskedCorners = []
        valueView.layer.borderWidth = 0
        nameView.subviews.forEach {
            if($0.tag == 4321){
                $0.removeFromSuperview()
            }
        }
        valueView.subviews.forEach {
            if($0.tag == 4321){
                $0.removeFromSuperview()
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

extension UIView {
    @discardableResult
    func addBorders(edges: UIRectEdge,
                    color: UIColor,
                    inset: CGFloat = 0.0,
                    thickness: CGFloat = 1.0) -> [UIView] {

        var borders = [UIView]()

        @discardableResult
        func addBorder(formats: String...) -> UIView {
            let border = UIView(frame: .zero)
            border.backgroundColor = color
            border.tag = 4321
            border.translatesAutoresizingMaskIntoConstraints = false
            addSubview(border)
            addConstraints(formats.flatMap {
                NSLayoutConstraint.constraints(withVisualFormat: $0,
                                               options: [],
                                               metrics: ["inset": inset, "thickness": thickness],
                                               views: ["border": border]) })
            borders.append(border)
            return border
        }


        if edges.contains(.top) || edges.contains(.all) {
            addBorder(formats: "V:|-0-[border(==thickness)]", "H:|-inset-[border]-inset-|")
        }

        if edges.contains(.bottom) || edges.contains(.all) {
            addBorder(formats: "V:[border(==thickness)]-0-|", "H:|-inset-[border]-inset-|")
        }

        if edges.contains(.left) || edges.contains(.all) {
            addBorder(formats: "V:|-inset-[border]-inset-|", "H:|-0-[border(==thickness)]")
        }

        if edges.contains(.right) || edges.contains(.all) {
            addBorder(formats: "V:|-inset-[border]-inset-|", "H:[border(==thickness)]-0-|")
        }

        return borders
    }
}
