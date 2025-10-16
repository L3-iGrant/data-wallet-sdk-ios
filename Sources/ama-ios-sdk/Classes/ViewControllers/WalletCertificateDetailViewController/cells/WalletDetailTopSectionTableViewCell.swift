//
//  WalletDetailTopSectionTableViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 22/01/21.
//

import UIKit

class WalletDetailTopSectionTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var orgImageView: UIImageView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var logoBgBtn: UIButton!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        logoImageView.layer.cornerRadius =  logoImageView.frame.size.height/2
        logoBgBtn.layer.cornerRadius =  logoBgBtn.frame.size.height/2
        addGradient()
    }
    
    func addGradient(){
        let statusBarBgView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: UIApplicationUtils.shared.getTopVC()?.view.frame.width ?? self.frame.width, height: 100))
        let gradient:CAGradientLayer = CAGradientLayer()
        gradient.frame.size = statusBarBgView.frame.size
        gradient.colors = [UIColor.white.withAlphaComponent(0.4).cgColor,UIColor.white.withAlphaComponent(0).cgColor] //Or any colors
        statusBarBgView.layer.addSublayer(gradient)
        self.addSubview(statusBarBgView)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

}
