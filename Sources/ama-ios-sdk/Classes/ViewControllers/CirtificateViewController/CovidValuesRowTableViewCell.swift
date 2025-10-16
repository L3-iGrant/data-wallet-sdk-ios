//
//  CovidValuesRowTableViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 21/12/21.
//

import UIKit

final class CovidValuesRowTableViewCell: UITableViewCell {
    
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var mainLbl: UILabel!
    @IBOutlet weak var top: NSLayoutConstraint!
    @IBOutlet weak var bottom: NSLayoutConstraint!
    @IBOutlet weak var contentBack: UIView!
    @IBOutlet weak var blurView: BlurredTextView!
    @IBOutlet weak var frameView: UIView!
    @IBOutlet weak var containerStack: UIStackView!
    @IBOutlet weak var leftPadding: NSLayoutConstraint!
    @IBOutlet weak var rightPadding: NSLayoutConstraint!
    @IBOutlet weak var containerStackRighConstaint: NSLayoutConstraint!
    @IBOutlet weak var checkBoxButton: UIButton!
    
    @IBOutlet weak var checkBoxButtonWidth: NSLayoutConstraint!
    
    @IBOutlet weak var checkBoxLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var frameViewLeadingConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var frameViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var lineViewTrailingSpace: NSLayoutConstraint!
    
    var tapGesture = UITapGestureRecognizer()
    var rightImage: UIImage? {
        didSet {
            rightImageView.isHidden = false
            rightImageView.image = rightImage
            rightImageView.contentMode = .center
        }
    }
    
    var onCheckboxToggle: ((_ isChecked: Bool, _ sessionItem: SessionItem?) -> Void)?
    var sessionItem: SessionItem? = nil
    private var isChecked = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        regularCell()
        rightImageView.isHidden = true
    }
    
    func removePadding(){
        leftPadding.constant = 0
        rightPadding.constant = 0
        self.updateConstraintsIfNeeded()
    }
    
    func setPadding(padding: CGFloat) {
        leftPadding.constant = padding
        rightPadding.constant = padding
        self.updateConstraintsIfNeeded()
    }
    
    func setCheckboxSelected(_ selected: Bool, sessionItem: SessionItem?, isMultipleOptions: Bool = false, isFromPWA: Bool = false, isPWAMandatory: Bool = false) {
        checkBoxButton.isHidden = false
        checkBoxButtonWidth.constant = 20
        frameViewLeadingConstraint.constant = 10
        self.sessionItem = sessionItem
        if (selected || sessionItem?.type == "MandatoryWithSingleOption" || isMultipleOptions) {
            if sessionItem?.type == "MandatoryWithSingleOption" || isMultipleOptions || isPWAMandatory{
                checkBoxButton.isUserInteractionEnabled = false
                checkBoxButton.tintColor = .systemGray
            } else {
                if isFromPWA {
                    checkBoxButton.tintColor = .darkGray
                    checkBoxButton.isUserInteractionEnabled = true
                } else {
                    checkBoxButton.tintColor = .systemGray
                    checkBoxButton.isUserInteractionEnabled = false
                }
                
            }
            checkBoxLeadingConstraint.constant = 20
            let newIcon =  "checkmark.square.fill"
            checkBoxButton.setImage(UIImage(systemName: newIcon), for: .normal)
        } else {
            checkBoxLeadingConstraint.constant = 20
            let newIcon =  "square"
            checkBoxButton.setImage(UIImage(systemName: newIcon), for: .normal)
            if isFromPWA {
                checkBoxButton.isUserInteractionEnabled = true
                checkBoxButton.tintColor = .darkGray
            } else {
                checkBoxButton.isUserInteractionEnabled = false
                checkBoxButton.tintColor = .systemGray
            }
        }
        lineViewTrailingSpace.constant = 2
        frameViewTrailingConstraint.constant = 0
    }
    
    func setData(model: IDCardAttributes, blurStatus: Bool, makeFirstLetterUppercase: Bool = true, isFromVerification: Bool = false) {
        self.arrangeStack(status: model.alignmentCalculated ?? false)
        if makeFirstLetterUppercase {
            mainLbl.text = model.name?.uppercaseFirstWords
        } else {
            mainLbl.text = model.name ?? ""
        }
        blurView.isFromVerification = isFromVerification
        if model.value?.isNotEmpty ?? true {
            blurView.text = model.value
        } else {
            blurView.text = "NA"
        }
        if isFromVerification {
            if sessionItem != nil {
                lineViewTrailingSpace.constant = 2
                frameViewTrailingConstraint.constant = 0
            } else {
                lineViewTrailingSpace.constant = 22
                frameViewTrailingConstraint.constant = 20
            }
        }
        disableCheckBox()
        blurView.blurStatus = blurStatus
    }
    
    func setDataGeneral(model: SelfAttestedModel, index: Int, blurStatus: Bool) {
        switch index {
        case 0:
            mainLbl.text = LocalizationSheet.ticket_no.localize
            blurView.text =  model.attributes?.ticketNumber?.value ?? "NA"
        default:
            mainLbl.text = LocalizationSheet.registration.localize
            blurView.text = model.attributes?.registration?.value ?? "NA"
        }
        blurView.blurStatus = blurStatus
    }
    
    func disableCheckBox() {
        checkBoxButton.isHidden = true
        checkBoxButtonWidth.constant = 0
        checkBoxLeadingConstraint.constant = 0
        frameViewLeadingConstraint.constant = 20
    }
    
    func setPassportData(model: IDCardAttributes, blurStatus: Bool) {
        self.arrangeStack(status: model.alignmentCalculated ?? false)
        mainLbl.text = model.name
        if model.value?.isNotEmpty ?? true {
            blurView.text = model.value
        } else {
            blurView.text = "NA"
        }
        blurView.blurStatus = blurStatus
    }
    
    func renderUI(index: Int, tot: Int) {
        if tot == 1 {
            roundAllCorner()
        } else if index == 0  {
            roundTop()
        } else if index == (tot - 1) {
            roundBottom()
        } else {
            regularCell()
        }
    }
    
    // Setting card color based on credential branding
    func renderForCredentialBranding(clr: UIColor) {
        lineView.backgroundColor = clr
        mainLbl.textColor = clr.withAlphaComponent(0.5)
        contentBack.backgroundColor = clr.withAlphaComponent(0.1)
        blurView.textColor = clr
    }
    
    func renderForPKPass(clr: UIColor) {
        lineView.backgroundColor = clr
        mainLbl.textColor = clr
        contentBack.backgroundColor = clr.withAlphaComponent(0.1)
        blurView.textColor = clr
    }
    
    private func arrangeStack(status: Bool) {
        if status {
            containerStack.axis = .vertical
            containerStack.spacing = 5
        } else {
            containerStack.axis = .horizontal
        }
    }
    
    private func roundTop() {
        top.constant = 8
        bottom.constant = 0
        contentBack.topMaskedCornerRadius = 10
        lineView.isHidden = false
    }
    
    private func roundBottom() {
        top.constant = 0
        bottom.constant = 8
        contentBack.bottomMaskedCornerRadius = 10
        lineView.isHidden = true
    }
    
    private func roundAllCorner(){
        top.constant = 8
        bottom.constant = 8
        contentBack.maskedCornerRadius = 10
        lineView.isHidden = true
    }
    
    private func regularCell() {
        top.constant = 0
        bottom.constant = 0
        contentBack.IBcornerRadius = 0
        lineView.isHidden = false
    }
    
    func arrangeStackForDataAgreement(isFromVerification: Bool = false) {
        self.arrangeStack(status: self.checkAlignment(isFromVerification: isFromVerification))
    }
    
    private func checkAlignment(isFromVerification: Bool = false) -> Bool {
        let font = UIFont.systemFont(ofSize: 15)
        let font_2 = UIFont.systemFont(ofSize: 14)
        var width = (ScreenMain.init().width ?? 0) - 70
        //Consider min space between name and value as 15
        let space: CGFloat = 15
        let labelWidth = width - space
        if !rightImageView.isHidden {
            width = width - 60
        }
        let mainLabelText = mainLbl.text ?? mainLbl.attributedText?.string ?? ""
        
        let blurViewText = isFromVerification ? blurView.blurLabelVerification.text ?? blurView.blurLabelVerification.attributedText?.string ?? "" : blurView.blurLbl.text ?? blurView.blurLbl.attributedText?.string ?? ""
//        blurView.blurLabelVerification.text ?? blurView.blurLabelVerification.attributedText?.string ?? ""
        if blurViewText.range(of: "\n") != nil {
            return true
        }
        let nameWidth : CGFloat = mainLabelText.widthOfString(usingFont: font)
        let valueWidth : CGFloat = blurViewText.widthOfString(usingFont: font_2)
        let totWidth = nameWidth + valueWidth
        if totWidth > labelWidth {
            return true
        } else {
            return false
        }
    }
    
}
